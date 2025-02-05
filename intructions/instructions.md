# Fitness AI Trainer - Product Requirements Document

## 1. Product Overview
Fitness AI Trainer is a mobile application that enables personal trainers to create and share structured workout routines through short-form vertical videos. The app combines TikTok-style video engagement with professional fitness instruction, allowing users to browse, interact with, and follow trainers while discovering personalized workout content.

### 1.1 Purpose
To provide personal trainers with a platform to expand their reach, engage users, and deliver high-quality, structured workout content through an interactive, video-based experience.

### 1.2 Target Audience
- **Primary:** Personal trainers looking to digitize and scale their fitness coaching business.
- **Secondary:** Fitness enthusiasts seeking guided workout routines and expert-led training content.

---

## 2. Technical Specifications
- **Frontend:** Flutter
- **Backend:** Firebase
- **Authentication:** Firebase Authentication (Google SSO & Email/Password)
- **Database:** Firestore (for storing user, routine, and interaction data)
- **Storage:** Firebase Storage (for videos and images)

---

## 3. Core Features

### 3.1 Authentication Flow
#### Role Selection
- Users choose between **"Trainer"** or **"User"** during onboarding.
- Visual cards with distinct icons and descriptions for each role.
- "Continue" button is enabled only after selecting a role.

#### Authentication Methods
- **Google Sign-In** integration.
- **Email/Password authentication** with secure validation.
- Password requirements:
  - Minimum **8 characters**
  - At least **one number**
  - One **special character**
- "Remember Me" functionality for persistent login.
- Password recovery option.
- Terms of Service and Privacy Policy acknowledgment before account creation.


---

### 3.2 Trainer Dashboard
#### Bottom Navigation

- **My Routines** – Stopwatch icon
- **Profile** – Person icon
- **Logout** – Power icon

#### My Routines (Trainer Home Screen)
- Displays a **list of created routines** with analytics (views, likes).
- Ability to **edit or delete** existing routines.
- Floating Action Button (**+ New Routine**) to create a new routine.

#### Routine Creation & Editor & view 

- **List view** of exercises within a routine.
- "Add Exercise" button (**+**).
- Configuration for each exercise:
  - Exercise name
  - Number of sets
  - Video upload/recording
- Ability to **reorder** exercises within a routine.
- **Delete exercises** if necessary.
##### View rutine 

- TikTok-style **infinite vertical scrolling** of trainer videos.
- Each **video represents a workout routine**, allowing users to preview exercises.
- Users can **react** (like) to videos and **follow** trainers.
- **Search bar** for finding trainers by name, category, or specialization.
- "Followed Trainers" filter to browse content from trainers a user follows.
---

### 3.3 Profile Management
- Trainers can edit:
  - **Profile picture**
  - **Username**
  - **Years of experience**
  - **Bio**
  - **Specializations** (e.g., weight loss, bodybuilding, mobility training).
- Users can **view trainer profiles**, see their videos, and follow/unfollow trainers.

---

### 3.4 User Engagement Features
- **React** (like) to videos.
- **Follow/unfollow trainers** to personalize the feed.
- **Commenting & Discussions** (Future Phase).
- **Save routines** for later (Future Phase).

---

## 4. User Experience Requirements

### 4.1 Video Playback & Feed Navigation
- **Infinite vertical scrolling** between trainer videos.
- **Tap to pause/play** videos.
- **Auto-play on scroll** for seamless experience.
- **Double tap to like** a workout routine.
- **Follow button on video overlay** to quickly follow a trainer.

---

### 4.2 Exercise Creation Flow (Trainer Only)
1. Tap **"Create New Routine"**.
2. Input routine details (Title, Description, Difficulty).
3. Tap **"Add Exercise"** → Name, Sets, Upload Video.
4. Arrange exercises in the desired sequence.
5. **Publish Routine** → Workout is now discoverable in the feed.

---

## 5. Data Models

### 5.1 User Profile
```json
{
  "uid": "string",
  "role": "trainer" | "user",
  "username": "string",
  "profilePicture": "string",
  "yearsExperience": "number",
  "bio": "string",
  "specializations": ["string"],
  "followersCount": "number",
  "followingCount": "number",
  "createdAt": "timestamp"
}


5.2 Routine (Workout Program)

{
  "routineId": "string",
  "trainerId": "string",
  "title": "string",
  "description": "string",
  "difficulty": "basic" | "intermediate" | "advanced",
  "exercises": ["exerciseId"],
  "videoUrl": "string",
  "likes": "number",
  "viewCount": "number",
  "createdAt": "timestamp"
}
5.3 Exercise (Individual Workout Step)

{
  "exerciseId": "string",
  "name": "string",
  "sets": "number",
  "videoUrl": "string",
  "order": "number"
}
5.4 User Interaction (Reactions & Follows)

{
  "interactionId": "string",
  "userId": "string",
  "routineId": "string",
  "reactionType": "like" | "comment",
  "createdAt": "timestamp"
}

{
  "followId": "string",
  "followerId": "string",
  "followingId": "string",
  "createdAt": "timestamp"
}


6. Future Considerations
6.1 Phase 2 Features
User workout tracking (log completed workouts).
Social sharing capabilities (share routines on social media).
Comments & feedback system for deeper engagement.
Trainer analytics dashboard (views, engagement stats).
Subscription & monetization features (paid workouts, premium content).
6.2 Technical Scalability
Video compression for optimized storage.
CDN integration for fast video streaming.
Caching strategies to reduce load times.
Offline mode support for saved workouts.
7. Success Metrics
Trainer engagement rate (number of active trainers).
User workout completion rates.
Video engagement metrics (likes, views, watch time).
Routine creation frequency (how often trainers create new content).
Platform growth metrics (new sign-ups, retention).
8. Revised User Flow
User downloads the app & selects their role (Trainer or User).
Authentication via Google or Email/Password.
For Trainers: Redirect to profile setup → Dashboard → Routine creation.
For Users: Redirect to TikTok-style workout feed.
Users can scroll through workouts, like routines, and follow trainers.
Trainers create and upload workout routines, which appear in the