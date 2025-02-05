# Fitness AI Trainer App

A Flutter application that enables fitness trainers to create, manage, and share workout routines with video demonstrations.

## Features

### For Trainers
- 🎥 Record and upload exercise videos
- 📝 Create and manage workout routines
- 👤 Personalized profile management
- 📊 Track routine engagement
- 🔄 Edit and update routines

### Technical Features
- 🔐 Google Sign-In authentication
- 📱 iOS & Android support
- 🎬 Video recording and playback
- ☁️ Cloud storage for videos
- 🔥 Real-time database updates

## Getting Started

### Prerequisites
- Flutter SDK (3.6.1 or higher)
- iOS 13.0+ / Android SDK 21+
- Firebase project
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. Clone the repository

bash
git clone https://github.com/yourusername/fitness-ai-trainer.git
cd fitness-ai-trainer

2. Install dependencies

bash
flutter pub get

3. iOS Setup

bash
cd ios
pod install
cd ..

4. Configure Firebase
- Create a new Firebase project
- Add iOS and Android apps in Firebase console
- Download and add configuration files:
  - iOS: `GoogleService-Info.plist`
  - Android: `google-services.json`

5. Run the app
bash
flutter run

### Environment Setup

Ensure you have the following environment variables set up:
- Firebase configuration
- Google Sign-In credentials

## Project Structure
lib/
├── features/
│ ├── authentication/
│ ├── trainer/
│ └── home/
├── shared/
└── main.dart



## Firebase Configuration

### Security Rules

The app uses Firebase Security Rules for data protection:

1. Firestore Rules
- Trainer profile management
- Routine CRUD operations
- Stats tracking

2. Storage Rules
- Video upload restrictions
- Profile picture management

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request



## Acknowledgments

- Flutter Team
- Firebase
- Contributors and testers
