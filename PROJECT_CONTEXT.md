# Veroon Business Dashboard — Project Context

## Project Identity

- **Product name:** Veroon Business Dashboard
- **Repository:** https://github.com/Moses361/business_dash
- **Project directory:** `C:\Development\business_dash`
- **Primary branch:** `main`
- **Framework:** Flutter and Dart
- **Platforms:** Android is the primary validated platform; web development remains a separate milestone.
- **Firebase project:** `veroon-business-dashboard`

Veroon is a business-management application for small businesses, initially targeting retail businesses such as motorcycle spare-parts shops, agrovets, hardware shops, electronics shops, and general retailers in Kenya.

## Current Project Status

The project has progressed beyond the original static UI prototype.

The Android application has been installed and tested on a physical Samsung device. The owner sign-in flow, dashboard, sidebar navigation, product and sales workflows, and existing business data have been verified by the developer.

The developer has also tested business data synchronization across devices and reported that products and sales work as expected. The application reports successful cloud synchronization, including successful uploads in the tested workflows.

These results represent developer testing. A formal release acceptance test, full backup-restoration test, and comprehensive security review remain necessary before final client handover.

## Technology and Services

- Flutter and Dart
- Android SDK
- SQLite for local business data
- Firebase Authentication
- Cloud Firestore for cloud-synchronized business records
- Firebase Security Rules
- Git and GitHub
- VS Code and Git Bash

## Architecture

The project separates application responsibilities across screens, models, services, repositories, and database components.

Relevant directories include:

```text
lib/
  main.dart
  screens/
  widgets/
  models/
  services/
  database/
  repositories/
```

The actual implementation in the repository is the source of truth. Do not assume every planned module exists or is complete without inspecting its implementation.

## Implemented and Tested Areas

### Android application

- Application launches on a physical Android device.
- Dashboard and sidebar navigation are working.
- Existing product and business data load after sign-in.
- Owner sign-in has been tested.
- Product and sales workflows have been exercised.
- Developer-reported multi-device testing indicates that products and sales behave as expected across devices.

### Local data and cloud synchronization

- Local business data is persisted in the application.
- Firebase Authentication and Cloud Firestore are configured.
- Firestore security rules have been deployed.
- The application provides a synchronization workflow.
- Successful uploads have been reported during testing.

**Important:** Sync status messages alone do not prove that every record type, deletion, conflict, or account-permission scenario works. Continue testing these cases before release.

### Backup and restoration

The application includes backup and database-restoration functionality. Backup operations have reported success during developer testing.

Restoration must be tested independently using a known backup before this feature is considered release-verified.

### Authentication and access control

The application includes sign-in and a pending-access flow for accounts without an approved Veroon profile or staff membership.

This pending-access behavior is intentional for a new device or an account awaiting approval. Preserve the existing access-control logic while making UI and branding changes.

Owner and staff provisioning, business membership, and role-specific permissions must be reviewed before client handover.

## Firebase and Security Notes

- Firebase project ID: `veroon-business-dashboard`
- Firestore rules are maintained in `firestore.rules`.
- The `.firebaserc` file associates the local Firebase CLI configuration with the project.
- Keep the default-deny behavior for unauthorized Firestore access.
- Never commit passwords, service-account private keys, or other secrets.
- Never weaken security rules merely to make synchronization work.
- Verify membership and authorization on the server-enforced security boundary.

Firebase client configuration is not the same as a service-account private key. Nevertheless, all Firebase access must be protected by appropriate authentication and security rules.

## Current Git Checkpoint

The latest recorded application milestone is:

`adde6c5 — Milestone: verify Android app and multi-device sync`

Use Git commits before significant changes and preserve known-working versions.

## Remaining Milestones

1. Replace generic application icons with the approved Veroon branding and supplied images.
2. Test synchronization for products, sales, expenses, edits, and deletions across devices.
3. Verify owner and staff account creation and role-specific access.
4. Test backup restoration using a known backup.
5. Review security, error handling, and offline behavior.
6. Test PDF/report output and business calculations.
7. Complete release APK installation and final client acceptance testing.
8. Plan and implement the separate web application milestone.

## Development Principles

- Preserve working functionality when updating individual screens.
- Inspect the existing implementation before adding duplicate services or features.
- Prefer small, verifiable changes with Git checkpoints.
- Never record a planned or partially tested feature as fully complete.
- Use test data during synchronization and restoration testing.
- Protect client data and credentials throughout development.
