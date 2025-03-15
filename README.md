# Gotong Royong

A Flutter application for organizing community service activities such as neighborhood clean-ups or public facility construction.

## Description

Gotong Royong is a community-based application that helps users organize and participate in local community service events. The app allows users to create events, join existing events, manage tasks, and share photos of their activities. It's built with Flutter and Firebase, providing a responsive and real-time experience across devices.

## Features

### Event Management
- Create community service events with title, description, location, date, and time
- View events in a calendar interface
- Join or leave events
- Track event participants

### Task Management
- Add tasks to events
- Assign tasks to participants
- Mark tasks as completed

### Photo Gallery
- Upload photos of events
- View photo galleries for each event

### User Authentication
- Sign up and login with email and password
- User profiles with personal information

## Technologies Used

- **Flutter**: UI framework for cross-platform development
- **Firebase**:
  - Authentication: User management
  - Firestore: Database for events, tasks, and user data
  - Storage: For storing event images
- **Provider**: State management
- **table_calendar**: Calendar widget for event scheduling
- **image_picker**: For selecting images from gallery or camera
- **cached_network_image**: For efficient image loading and caching

## Installation

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Setup

1. Clone the repository
   ```
   git clone https://github.com/yourusername/gotong-royong.git
   ```

2. Navigate to the project directory
   ```
   cd gotong-royong
   ```

3. Install dependencies
   ```
   flutter pub get
   ```

4. Configure Firebase
   - Create a new Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and add the google-services.json (for Android) or GoogleService-Info.plist (for iOS) to the appropriate directory
   - Enable Authentication, Firestore, and Storage services

5. Run the app
   ```
   flutter run
   ```

## Usage

### Creating an Event
1. Log in to the app
2. Navigate to the home screen
3. Tap the floating action button to create a new event
4. Fill in the event details (title, description, location, date, time)
5. Add images if desired
6. Submit the event

### Joining an Event
1. Browse events on the calendar
2. Tap on an event to view details
3. Tap the "Join" button to participate

### Adding Tasks
1. Open an event you've created or joined
2. Navigate to the Tasks tab
3. Tap the add button to create a new task
4. Fill in task details and assign to participants if desired

### Uploading Photos
1. Open an event
2. Navigate to the Photos tab
3. Tap the add button to upload photos from your device

## Project Structure

```
assets/
  images/
lib/
  main.dart           # Application entry point
  screens/            # UI screens
    add_task_screen.dart
    create_event_screen.dart
    event_detail_screen.dart
    home_screen.dart
    login_screen.dart
    photo_gallery_screen.dart
    profile_screen.dart
  services/           # Business logic and data services
    auth_service.dart
    event_service.dart
pubspec.yaml         # Dependencies and assets configuration
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- [table_calendar](https://pub.dev/packages/table_calendar)
- [Provider](https://pub.dev/packages/provider)