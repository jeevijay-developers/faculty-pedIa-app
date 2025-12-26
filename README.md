# Faculty Pedia Mobile App

A comprehensive Flutter mobile application for Faculty Pedia - an educational platform connecting students with top educators.

## Features

### Core Features
- **User Authentication**: JWT-based login/signup for Students and Educators
- **Home Dashboard**: Browse exam categories, courses, and quick actions
- **Educators**: Browse, search, and view educator profiles
- **Courses**: Browse courses, view details, and enroll
- **Test Series**: Access practice tests with timed assessments
- **Live Tests**: Take real-time tests with scoring
- **Webinars**: Join live and upcoming webinars
- **Profile Management**: View and edit user profile

### Additional Features
- **Dark Mode**: Full dark theme support
- **Biometric Login**: Fingerprint/Face ID authentication
- **Offline Mode**: Local data caching support
- **Push Notifications**: Firebase-based notifications

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Local Storage**: Hive, SharedPreferences, FlutterSecureStorage
- **Push Notifications**: Firebase Messaging
- **Biometric Auth**: local_auth

## Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode
- Firebase project (for push notifications)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd faculty_pedia
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API

Update the backend URL in `lib/core/config/app_config.dart`:

```dart
static const String baseUrl = 'https://faculty-pedia-backend.onrender.com';
```

### 4. Firebase Setup (Optional - for Push Notifications)

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` for Android → place in `android/app/`
   - `GoogleService-Info.plist` for iOS → place in `ios/Runner/`

### 5. Run the App

```bash
# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run on any available device
flutter run
```

## Building for Production

### Android APK

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA

```bash
# Build iOS app
flutter build ios --release

# Open Xcode for archive and distribution
open ios/Runner.xcworkspace
```

Then in Xcode:
1. Select Product → Archive
2. Choose Distribute App
3. Follow the export wizard

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── config/              # App configuration
│   ├── router/              # Navigation setup
│   ├── services/            # API, storage, notification services
│   ├── theme/               # App theming
│   └── utils/               # Utility functions
├── features/
│   ├── auth/                # Login, Signup, Forgot Password
│   ├── splash/              # Splash screen
│   ├── home/                # Home dashboard
│   ├── educators/           # Educators list & profiles
│   ├── courses/             # Courses list & details
│   ├── exams/               # Exam categories
│   ├── test_series/         # Test series
│   ├── live_test/           # Live test taking
│   ├── webinars/            # Webinars
│   ├── profile/             # User profile
│   └── settings/            # App settings
└── shared/
    ├── models/              # Data models
    └── widgets/             # Reusable widgets
```

## Screens

1. **Splash Screen** - App initialization with branding
2. **Login Screen** - Email/password authentication
3. **Signup Screen** - Student/Educator registration
4. **Forgot Password** - Password reset flow
5. **Home Dashboard** - Main landing with categories
6. **Educators List** - Browse all educators
7. **Educator Profile** - Detailed educator view
8. **Courses List** - Browse all courses
9. **Course Details** - Course information and enrollment
10. **Exams Screen** - IIT-JEE, NEET, CBSE categories
11. **Exam Details** - Courses and tests by exam type
12. **Test Series** - Available test series
13. **Test Series Details** - Tests within a series
14. **Live Test** - Test taking interface
15. **Test Results** - Score and performance analysis
16. **Webinars List** - Upcoming and past webinars
17. **Webinar Details** - Webinar information
18. **Profile** - User profile and stats
19. **Edit Profile** - Update user information
20. **Settings** - App preferences and logout

## API Integration

The app connects to the Faculty Pedia backend at:
```
https://faculty-pedia-backend.onrender.com
```

### Main Endpoints Used:
- `/api/auth/login-student` - Student login
- `/api/auth/login-educator` - Educator login
- `/api/auth/register-student` - Student registration
- `/api/educators` - Get all educators
- `/api/educators/:id` - Get educator by ID
- `/api/courses` - Get all courses
- `/api/courses/:id` - Get course by ID
- `/api/test-series` - Get all test series
- `/api/webinars` - Get all webinars

## Environment Configuration

### Development
- API URL: `https://faculty-pedia-backend.onrender.com`
- Debug mode enabled

### Production
- Update `baseUrl` in `app_config.dart`
- Disable debug logging in API service

## Troubleshooting

### Common Issues

1. **Build fails on iOS**
   ```bash
   cd ios && pod install && cd ..
   flutter clean && flutter pub get
   ```

2. **Firebase errors**
   - Ensure config files are in correct locations
   - Check Firebase project settings

3. **API connection issues**
   - Verify backend URL is correct
   - Check network connectivity

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details
