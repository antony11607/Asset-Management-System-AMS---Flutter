# Asset Management System (AMS)

AMS is a Flutter application for managing organizational assets, user requests, and maintenance work. It uses Firebase for authentication and real-time data.

## Features

- **Employees:** Browse available assets, submit requests, and view assigned assets and request status.
- **Administrators:** Manage assets and user accounts, review requests, and monitor operations through dashboard reports.
- **Service providers:** View assigned maintenance tasks and track work progress and history.
- **Reporting:** Dashboard charts and Excel exports.
- **Authentication:** Sign in with an email address or username; access is based on account approval, status, and role.

## Technology

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- `fl_chart` for dashboard charts
- `excel` for spreadsheet exports

## Getting started

### Requirements

- Flutter SDK with Dart **3.12.2 or later**
- Android Studio or Xcode for the corresponding mobile target
- A Firebase project configured for the platforms you intend to run

### Setup

1. Clone the repository and enter the project directory:

   ```bash
   git clone https://github.com/antony11607/ams.git
   cd ams
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add the platform configuration files for Android and iOS.
   - Confirm the Firebase options in `lib/main.dart` are for your project when running on web.
   - Enable Firebase Authentication and Cloud Firestore, and deploy the repository's Firestore rules and indexes if needed.

4. Run the app:

   ```bash
   flutter run
   ```

## Application flow

1. Sign in or register.
2. The app checks account approval and active status.
3. AMS opens the dashboard for the user's role.
4. Employees request and track assets; administrators manage assets, users, and requests; service providers handle assigned maintenance tasks.

## Useful commands

```bash
flutter analyze
flutter test
```
