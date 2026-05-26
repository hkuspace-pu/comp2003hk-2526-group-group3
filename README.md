# Focus Aquarium
Focus Aquarium is a Flutter multi-plaform application designed to help users stay focused and build better habits. Users can record focus time, earn points from completed focus sessions, and use those points to buy fish for their virtual aquarium.

## Features
- Admin Side
	- Create an account for both user types
	- Manage the current list of user accounts
	- Approve the evidence that the user submits
	- Generate the report about the user

- User Side
	- Record focus time according to your activities
	- Earn points after completing focus sessions
	- Use points to buy fish and build your own virtual aquarium
	- Log your mood and upload the photo to record the activities
	- Gamification for a lucky draw to collect the hidden fish
	- Simple and friendly productivity experience

## Getting Started
This project is built with Flutter. Before running the app, make sure Flutter is installed on your machine.

### First Time Setup
After downloading or cloning this project from GitHub, run the following commands in the project root folder:
```bash
flutter clean
flutter pub get
flutter build apk
flutter build web
```

These commands help clean old build files, install all required dependencies, and build the project for the first time.

### Run the App
After setup, you can run the app with:

```bash
flutter run
```

## Project Structure
```text
lib/
  models/       # Data models
  screens/      # App screens
  services/     # Firebase and app services
  utils/        # Constants, colors, and helpers
  widgets/      # Reusable UI components
```

## Requirements
- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or physical device
- Firebase setup, if the project uses Firebase services

Stay focused, earn points, and grow your aquarium.
