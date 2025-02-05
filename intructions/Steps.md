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