# Veroon Business Dashboard — Project Handover

## Project objective
Build Veroon, a business management application for products,
inventory, sales, expenses, and reports.

Long-term goals:
- Owner and staff accounts
- Secure cloud database
- Android and web access
- Offline support and cloud synchronization
- Business subscription and license management

## Development environment
- Operating system: Windows
- Terminal: Git Bash / MINGW64
- Project folder: /c/Development/business_dash
- Framework: Flutter
- Local database: SQLite
- Firebase project ID: veroon-business-dashboard
- Android package ID: com.example.business_dash

## Existing application
- Home / Dashboard
- Products
- Sales
- Expenses
- Reports
- SQLite database: veroon.db
- Previously reported database schema version: 7

## Completed setup
- Firebase project created.
- Firebase CLI login succeeded.
- FlutterFire CLI generated lib/firebase_options.dart
  for Android.
- firebase_core dependency added.
- Firebase initialization added to lib/main.dart.
- flutter analyze completed with no errors.
- Analyzer reported 18 warnings/informational notices.

## Last known blocker
The Android phone was not reliably detected because of a
USB/ADB connection issue.

Flutter detected Windows, Chrome, and Edge as available targets.
The proposed next test was:

flutter run -d chrome

A successful launch has not yet been confirmed.

## Important data protection rules
- Preserve existing client SQLite records.
- Never clear application data or uninstall as a troubleshooting shortcut.
- Back up and verify the database before migration.
- Do not upload real business records until authentication,
  data design, and Firebase security rules are ready.
- Firebase initialization alone does not enable synchronization.
- Never commit passwords, private keys, or access tokens.

## Remaining milestones
1. Verify the app launches on a supported test target.
2. Verify database backup and restore.
3. Design owner/staff authentication and permissions.
4. Design the cloud database and security rules.
5. Implement and test cloud synchronization and offline handling.
6. Implement subscription and licensing requirements.
7. Build and test the web dashboard.
8. Test the complete system before deployment.

## Instructions for the next ChatGPT conversation
1. Read this file and the latest GitHub issue history.
2. Verify the current code before assuming previous work is complete.
3. Continue from the next unfinished task.
4. Give manageable steps with exact commands.
5. Protect all existing client business data.
6. Do not claim a feature works until it has been tested.

## Latest session update
Date: 2026-10-17
Completed: Created an initial project handover document.
Files changed: docs/PROJECT_HANDOVER.md
Outstanding: Confirm app launch and Firebase initialization.
Next action: Run flutter run -d chrome and report the result.

Update this section after every substantial development session.
