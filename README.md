# Veroon Business Dashboard

Veroon is a Flutter-based business-management application for small businesses, initially targeting retail businesses in Kenya.

The application is designed to support local business operations, with cloud synchronization and authenticated business access.

## Target Businesses

- Motorcycle spare-parts shops and workshops
- Agrovets
- Hardware shops
- Electronics shops
- General retail businesses

## Current Status

The Android application has been installed and exercised on a physical device. Developer testing has covered sign-in, dashboard and sidebar navigation, product and sales workflows, and multi-device data synchronization.

The developer reports that products and sales behaved as expected across devices.

The project remains under development. Branding improvements, broader synchronization tests, staff-access verification, backup-restoration testing, and release acceptance checks remain.

## Technology

- Flutter
- Dart
- Android
- SQLite for local data
- Firebase Authentication
- Cloud Firestore
- Firebase Security Rules
- Git and GitHub

## Repository

https://github.com/Moses361/business_dash

Firebase project ID: `veroon-business-dashboard`

## Project Structure

```text
lib/
├── main.dart
├── screens/
├── widgets/
├── models/
├── services/
├── database/
└── repositories/
```

The repository contains the implementation details and configuration for the current application. Consult the source code before assuming that a planned feature is fully implemented.

## Development Environment

Project directory:

`C:\Development\business_dash`

Open the project in a terminal and install dependencies:

```bash
flutter pub get
```

List connected devices:

```bash
flutter devices
```

Run the application on a connected Android device:

```bash
flutter run -d <device-id>
```

Check the project for static analysis issues:

```bash
flutter analyze
```

Run the available automated tests:

```bash
flutter test
```

Build a release APK when release checks are complete:

```bash
flutter build apk --release
```

The resulting APK is normally located at:

`build/app/outputs/flutter-apk/app-release.apk`

## Firebase and Security

Use the configured Firebase project and current Firestore rules.

Never disable security rules or commit passwords, private keys, or other secrets to make development easier. Ensure that business membership and permissions are enforced by Firebase security rules or other trusted server-side authorization.

## Documentation

- `PROJECT_CONTEXT.md` — architecture, project status, and remaining milestones.
- `DEVELOPMENT_LOG.md` — historical development milestones.
- `TODO.md` — current verification and delivery checklist.
- `Veroon App Documentation.docx` — product-facing application documentation.

## Next Milestones

1. Complete Veroon branding and image updates.
2. Expand multi-device synchronization testing.
3. Verify owner and staff access permissions.
4. Test backup restoration.
5. Complete release validation and client handover.
6. Plan the separate web application.

## Flutter Resources

- https://docs.flutter.dev/get-started/learn-flutter
- https://docs.flutter.dev/get-started/codelab
