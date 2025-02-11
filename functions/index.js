const functions = require('firebase-functions');
const admin = require('firebase-admin');
const OpenAI = require('openai');
const axios = require('axios');

// Initialize Firebase Admin
admin.initializeApp();

// Function to convert image URL to base64
async function getImageAsBase64(url) {
  try {
    const response = await axios.get(url, { responseType: 'arraybuffer' });
    return Buffer.from(response.data, 'binary').toString('base64');
  } catch (error) {
    console.error('Error downloading image:', error);
    throw error;
  }
}

// Function to parse equipment from OpenAI response
function parseEquipment(content) {
  try {
    // Try parsing as JSON first
    const parsed = JSON.parse(content);
    if (Array.isArray(parsed)) {
      return parsed;
    }
  } catch (e) {
    // If JSON parsing fails, try to extract equipment names from text
    const lines = content.split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => line.replace(/^[-*•]?\s*/, '')) // Remove bullet points
      .map(line => line.toLowerCase());
    return lines;
  }
  return [];
}

// Cloud Function to detect gym equipment in location photos
exports.detectGymEquipment = functions.https.onCall(async (data, context) => {
  // Initialize OpenAI with the API key from Firebase config
  const openai = new OpenAI({
    apiKey: functions.config().openai.key
  });

  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { locationId } = data;
  if (!locationId) {
    throw new functions.https.HttpsError('invalid-argument', 'Location ID is required');
  }

  try {
    // Get location data from Firestore
    const locationDoc = await admin.firestore().collection('locations').doc(locationId).get();
    
    if (!locationDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Location not found');
    }

    const location = locationDoc.data();
    const photoUrls = location.photoUrls || [];
    
    if (photoUrls.length === 0) {
      return { message: 'No photos to analyze' };
    }

    // Analyze each image and collect equipment
    const equipmentSet = new Set();
    
    for (const photoUrl of photoUrls) {
      // Convert image to base64
      const base64Image = await getImageAsBase64(photoUrl);
      
      const response = await openai.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "List all gym or fitness equipment present in this image. Return only equipment names, one per line. If no equipment is found, return an empty response."
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`
                }
              },
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.5
      });

      const content = response.choices[0].message.content;
      const equipment = parseEquipment(content);
      equipment.forEach(item => {
        if (item) equipmentSet.add(item.toLowerCase().trim());
      });
    }

    // Update location with detected equipment
    const uniqueEquipment = Array.from(equipmentSet);
    if (uniqueEquipment.length > 0) {
      await admin.firestore().collection('locations').doc(locationId).update({
        equipment: admin.firestore.FieldValue.arrayUnion(...uniqueEquipment),
        lastEquipmentScanTime: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    return {
      success: true,
      detectedEquipment: uniqueEquipment
    };

  } catch (error) {
    console.error('Error in detectGymEquipment:', error);
    throw new functions.https.HttpsError('internal', 'Error processing request');
  }
});

// Cloud Function to generate workout routines using OpenAI
exports.generateWorkoutRoutine = functions.https.onCall(async (data, context) => {
  // Initialize OpenAI with the API key from Firebase config
  const openai = new OpenAI({
    apiKey: functions.config().openai.key
  });

  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { numberOfDays, durationMinutes, fitnessGoal, selectedEquipment } = data;

  // Validate input parameters
  if (!numberOfDays || !durationMinutes || !fitnessGoal || !selectedEquipment) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are an expert fitness trainer. Create a detailed workout routine following these strict formatting rules:

1. Use clear markdown headers:
   - # for the routine title
   - ## for each day (Day 1, Day 2, etc.)
   - ### for sections within each day (Warm-Up, Main Workout, Cool-Down)

2. Structure each day's content:
   \`\`\`markdown
   ## Day X

   ### Warm-Up (10 minutes)
   - Exercise 1: reps × sets | rest time
   - Exercise 2: reps × sets | rest time

   ### Main Workout (35 minutes)
   - Exercise 1: reps × sets | rest time
     * Form cue 1
     * Form cue 2
   
   ### Cool-Down (5 minutes)
   - Exercise 1: reps × sets
   - Exercise 2: reps × sets
   \`\`\`

3. Always include:
   - Specific rep ranges and sets
   - Rest periods between sets
   - Form cues for complex exercises
   - Clear separation between days using line breaks
   - Time estimates for each section`
        },
        {
          role: "user",
          content: `Create a ${numberOfDays}-day workout routine with these requirements:
- Session duration: ${durationMinutes} minutes
- Fitness goal: ${fitnessGoal}
- Available equipment: ${selectedEquipment.join(', ')}

The response must follow this exact format:
TITLE: [Descriptive name for the routine]
DESCRIPTION: [2-3 sentences summarizing the program]
OUTLINE:
[Full workout plan in markdown format following the system message structure]`
        }
      ],
      temperature: 0.7,
      max_tokens: 4000
    });

    const content = response.choices[0].message.content;
    console.log('Raw AI Response:', content);
    
    // Parse the response with improved handling
    const sections = content.split('\n');
    let title = '';
    let description = '';
    let outline = '';
    let currentSection = '';
    
    for (const line of sections) {
      const trimmedLine = line.trim();
      
      // Handle both title formats
      if (trimmedLine.startsWith('# ')) {
        title = trimmedLine.substring(2).trim();
        currentSection = 'title';
      } else if (trimmedLine.startsWith('TITLE:')) {
        title = trimmedLine.substring(6).trim();
        currentSection = 'title';
      } else if (trimmedLine.startsWith('DESCRIPTION:')) {
        currentSection = 'description';
        description = trimmedLine.substring(12).trim();
      } else if (trimmedLine.startsWith('OUTLINE:')) {
        currentSection = 'outline';
      } else if (trimmedLine) {
        switch (currentSection) {
          case 'description':
            if (!trimmedLine.startsWith('#')) {
              description += ' ' + trimmedLine;
            }
            break;
          case 'outline':
            if (trimmedLine.startsWith('#')) {
              outline += trimmedLine + '\n\n';
            } else {
              outline += trimmedLine + '\n';
            }
            break;
        }
      }
    }

    // Clean up the text
    title = title || sections.find(line => line.startsWith('# '))?.substring(2).trim() || '';
    description = description.trim();
    outline = outline.trim();

    // Validate the response
    if (!title || !description || !outline) {
      console.error('Invalid AI response format:', { title, description, outline });
      throw new Error('Failed to generate a properly formatted workout routine');
    }

    // Clean up the outline formatting
    outline = outline
      .replace(/\n{3,}/g, '\n\n') // Replace multiple line breaks with double line breaks
      .trim();

    return {
      title,
      description,
      outline
    };

  } catch (error) {
    console.error('Error generating workout routine:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate workout routine: ' + error.message);
  }
});
