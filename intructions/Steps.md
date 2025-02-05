# Fitness AI Trainer - Trainer Sign-Up and Profile Setup PRD

## 1. Overview
This document outlines the **Trainer Sign-Up and Profile Setup Process** for the Fitness AI Trainer app. After completing the sign-up process, trainers will be prompted to set up their profile by choosing a **unique username**, uploading a **profile picture**, and writing a **short bio**. Once this setup is complete, they will be directed to the **main trainer home screen**, which features a bottom navigation bar with the following options:
- **My Routines** – Stopwatch icon
- **Profile** – Person icon
- **Logout** – Power icon

---

## 2. Process Flow

### 2.1 Sign-Up Completion
- **Trigger:** Trainer completes the authentication process (via Google Sign-In or Email/Password).
- **Action:** The app redirects the trainer to the **Profile Setup Screen**.

---

### 2.2 Profile Setup Screen
- **Purpose:** Collect essential profile information from the trainer to personalize their account and make it discoverable to users.
- **UI Elements:**
  1. **Username Field:**
     - Input field for entering a unique username.
     - Real-time validation to check for uniqueness.
     - Error message: *"Username already taken. Please choose another."*
  2. **Profile Picture Upload:**
     - Option to upload a profile picture from the device gallery or take a new photo.
     - Image cropping tool for optimal display.
     - Default placeholder image if no picture is uploaded.
  3. **Bio Field:**
     - Text area for entering a short bio (max 150 characters).
     - Character counter displayed below the text area.
  4. **Continue Button:**
     - Enabled only when all fields are filled and the username is unique.
     - Redirects the trainer to the **main trainer home screen**.

---

### 2.3 Main Trainer Home Screen
- **Purpose:** The central hub for trainers to manage their routines, profile, and account.
- **UI Elements:**
  - **Bottom Navigation Bar:**
    1. **My Routines** – Stopwatch icon
       - Default screen displaying a list of created routines.
    2. **Profile** – Person icon
       - Redirects to the trainer's profile for viewing and editing.
    3. **Logout** – Power icon
       - Logs the trainer out of the app after confirmation.

---

## 3. Detailed Requirements

### 3.1 Profile Setup Screen Requirements
#### 3.1.1 Username Field
- **Validation:**
  - Username must be unique across the platform.
  - Real-time API call to check for uniqueness.
  - Minimum length: 3 characters.
  - Maximum length: 15 characters.
  - Allowed characters: Letters (A-Z, a-z), numbers (0-9), and underscores (_).
- **Error Handling:**
  - Display error message if username is already taken or invalid.
  - Disable the "Continue" button until a valid username is entered.

## 4. Data Models

### 4.1 User Profile
```json
{
  "uid": "string",
  "role": "trainer",
  "username": "string",
  "profilePicture": "string",
  "bio": "string",
  "createdAt": "timestamp"
}





Routine Section Implementation
Now, let’s build the Routine Section, where trainers can create, manage, and showcase their workout routines. This section will allow trainers to design structured workout plans while ensuring an engaging and interactive experience for users. Below are the key features:

1. My Routines (Trainer Dashboard)
Displays a list of created routines, including engagement analytics (views, likes).
Trainers can edit or delete existing routines.
Floating Action Button (+ New Routine) to create a new workout routine.
2. Routine Creation & Editor
List view displaying exercises within a routine.
Add Exercise button (+) to include new exercises.
Configuration options for each exercise:
Exercise Name
Number of Sets
Video Upload/Recording
Ability to reorder exercises within a routine.
Option to delete exercises if necessary.
3. Routine Viewing (User Experience)
TikTok-style infinite scrolling for easy discovery of workout routines.
Each video represents a workout routine, allowing users to preview exercises in a structured flow.
Users can react (like) to routines and follow trainers for personalized content.
Search functionality to find trainers by name, category, or specialization.
Followed Trainers Filter to browse content exclusively from trainers a user follows.
This structure ensures a seamless and engaging experience for both trainers and users, promoting routine discovery and trainer visibility while maintaining an intuitive workout creation process.




Routine Screen Functionality
In the Routines Screen, when a trainer selects a routine, it should display the workout videos in a TikTok-style format, allowing users to seamlessly scroll down to view the next exercise in the routine.

Routine Playback Features
Full-screen vertical video player displaying exercises in sequence.
Infinite scrolling to move to the next exercise in the routine.
Tap to pause/play functionality for better user control.
Routine Management (Trainer Controls)
Each routine card should include three action buttons:

Edit (📝 Icon) – Opens the Routine Editor, allowing trainers to modify exercises, reorder them, or upload new videos.
Delete (🗑️ Icon) – Allows trainers to permanently remove the routine after confirmation.
View (👁️ Icon) – Opens the routine in TikTok-style playback mode for review.
When a trainer selects Edit, they will be redirected to the Routine Editor, where they can update the routine structure and content.

This setup ensures a smooth and intuitive experience, allowing both trainers and users to navigate workouts effortlessly while providing trainers with easy-to-access editing and management tools. 