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
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: "You are an expert fitness trainer. Create a detailed workout routine based on the user's requirements. The response should be in a structured format with a title, description, and a markdown-formatted outline. Focus on proper form, progressive overload, and rest periods."
        },
        {
          role: "user",
          content: `Create a ${numberOfDays}-day workout routine with the following requirements:
          - Each workout session should last approximately ${durationMinutes} minutes
          - Main goal: ${fitnessGoal}
          - Available equipment: ${selectedEquipment.join(', ')}

          Please provide the response in the following format:
          TITLE: [A descriptive name for the routine]
          DESCRIPTION: [A brief summary of the program]
          OUTLINE:
          (A detailed, well-formatted Markdown workout plan)
          ### **Markdown Formatting Requirements**
              - Clearly separate each **days workout** with a new section ("### Day X").
              - Use **bold headers** for muscle groups or workout phases (e.g., "**Warm-Up**", "**Main Workout**", "**Cool-Down**").
              - Use bullet points ("-"") or numbered lists ("1.") for exercise details.
              - Include key details for **each exercise**:
                - Sets, reps, and rest periods.
                - Important form cues.
                - Modifications (if applicable).
              - Ensure readability with **line breaks between sections** to prevent clutter.

          For the outline:
          - Break down the routine by days
          - Include sets, reps, and rest periods
          - Provide form cues for exercises
          - Include warm-up and cool-down  `
        }
      ],
      temperature: 0.7,
      max_tokens: 2000
    });

    const content = response.choices[0].message.content;
    
    // Parse the response
    const sections = content.split('\n');
    let title = '';
    let description = '';
    let outline = '';
    let currentSection = '';
    
    for (const line of sections) {
      if (line.startsWith('TITLE:')) {
        currentSection = 'title';
        title = line.substring(6).trim();
      } else if (line.startsWith('DESCRIPTION:')) {
        currentSection = 'description';
        description = line.substring(12).trim();
      } else if (line.startsWith('OUTLINE:')) {
        currentSection = 'outline';
      } else if (line.trim()) {
        switch (currentSection) {
          case 'description':
            description += '\n' + line.trim();
            break;
          case 'outline':
            outline += line + '\n';
            break;
        }
      }
    }

    return {
      title,
      description: description.trim(),
      outline: outline.trim()
    };

  } catch (error) {
    console.error('Error generating workout routine:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate workout routine');
  }
});
