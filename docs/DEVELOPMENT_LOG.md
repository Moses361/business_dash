# Veroon Development Log

## 2026-10-17 — Firebase Setup
- Firebase project: `veroon-business-dashboard`.
- Android Firebase configuration generated.
- Firebase initialization added to `lib/main.dart`.
- An earlier analyzer run reportedly had no errors and 18 warnings/informational notices.
- Android USB/ADB detection was unreliable.
- Browser launch with `flutter run -d chrome` was proposed; success is unconfirmed.

## 2026-10-18 — Live-Sync Planning
- Firebase initialization and authentication routing were inspected.
- Products, sales, and expenses use local SQLite.
- Cloud backup stores snapshots, not live synchronization.
- Inspected Firestore rules did not yet permit shared live sync.
- A saved Git stash protects earlier branding and authentication-related changes.
- Live sync has not been implemented or verified.

## 2026-10-19 — Database Groundwork for Cloud Sync
- Database schema upgraded from version 7 to version 8.
- Added `sync_id`, `sync_status`, `updated_at`, and `deleted_at` metadata to products, sales, and expenses.
- Added indexes to support synchronization identifiers and status queries.
- Existing records are backfilled with synchronization metadata.
- New records use UUIDs and are marked pending synchronization.
- Product and expense deletion now uses soft-delete tracking; normal queries exclude deleted records.
- Sale and stock updates are performed transactionally, with checks for deleted products and insufficient stock.
- Improved product updates to prevent modifying deleted products.
- JSON backup restoration supports database versions 7 and 8, validates records, checks duplicate IDs, and creates a safety export before restoring.
- Formatting completed for the four changed Dart files.
- `flutter test` passed: 2 tests.
- `flutter analyze` reported 16 existing or outstanding warnings/informational issues, with no errors reported.
- Latest database groundwork commit: `18e915c chore: prepare database for cloud sync metadata`.
- These changes prepare the local database for future synchronization; they do not implement cloud upload/download or live multi-device sync.

## 2026-10-20 to 2026-10-23 — Firebase Authentication and Access Planning
- Confirmed the intended Firebase project is `veroon-business-dashboard`.
- Firebase project number: `538138025601`.
- Firebase CLI and FlutterFire CLI were installed and configured.
- Android Firebase configuration was generated for the application.
- Firebase Authentication and Cloud Firestore dependencies are present in the Flutter project.
- Firebase initialization and authentication-based routing were added to the application.
- `AuthGate` checks Firebase Authentication state and reads the signed-in user's Firestore profile.
- Access is allowed only when the user's profile has an approved `owner` or `staff` role.
- Missing profiles display a pending-access message; the client application does not assign its own approved role.
- Cloud Functions were checked, and no deployed functions were found.
- The Firebase project remains on the Spark plan, with no billing account linked.
- No trusted backend approval function has been implemented or deployed.
- Live synchronization remains unimplemented and unverified.

## 2026-10-24 — Owner Registration Request and Firestore Rules
### Completed
- Reviewed the existing owner login and registration screen.
- Backed up the original registration screen to `../veroon_auth_safety_backup/owner_login_screen_before_request.dart`.
- Updated `lib/screens/owner_login_screen.dart` to include a business-name field during registration.
- Added Firebase Authentication account creation for new registrants.
- Added a Firestore registration request at `accessRequests/{uid}`.
- Registration requests contain:
  - `businessName`
  - `email`
  - `status`, set to `pending`
  - `createdAt`, using `FieldValue.serverTimestamp()`
- Added user-facing success and error messages for the registration flow.
- The registration screen signs out after submitting a request so the unapproved user does not remain in the authenticated session.
- Updated `firestore.rules` to allow authenticated users to create their own pending registration requests and read their own request.
- Registration requests cannot be updated or deleted by clients.
- User profiles cannot be created or modified by client applications.
- Preserved the existing user-profile and cloud-backup rule structure.
- Ran `flutter pub get` successfully.
- Ran `flutter analyze`: 13 issues were reported, consisting of informational lint notices and warnings. No new registration-screen issues were reported.
- Ran `git diff --check` without whitespace errors.
- Confirmed the working tree contains modifications to the Firestore rules, registration screen, database service, product screen, sales screen, expense screen, and dependency files.

### Current Status
- The registration implementation has been edited and passes the reported analyzer check without new registration-screen issues.
- A debug APK build was started; successful completion has not yet been confirmed.
- Live Firebase registration has not yet been tested.
- Successful Firestore access-request creation has not yet been verified.
- The Firestore rules have not been deployed.
- Manual administrator approval is still required.
- No in-app administrator approval workflow exists.
- Business-level data isolation and staff membership permissions are not yet fully implemented.
- Live cloud synchronization is not implemented or verified.

## Next Steps
1. Confirm that `flutter build apk --debug` completes successfully.
2. Inspect the final working-tree changes and preserve all unrelated modifications.
3. Test the registration screen with a dedicated test email account.
4. Verify that the corresponding `accessRequests/{uid}` document is created in Firestore with the expected fields and pending status.
5. Test sign-in and confirm that unapproved accounts cannot enter the business dashboard.
6. Review Firestore rules against registration, user profiles, existing cloud backups, and future business membership requirements.
7. Deploy Firestore rules only after review and successful testing.
8. Establish a secure administrator approval procedure that does not allow client-side role escalation.
9. Design business-level data isolation before onboarding multiple businesses.
10. Plan staff accounts, business membership, and role-based permissions.
11. Continue synchronization work in small stages: upload/download, offline retries, conflict handling, deletion propagation, and multi-device testing.
12. Prevent duplicate sales and double stock deductions during synchronization retries.
13. Test data consistency across two devices before claiming live synchronization is operational.
14. Commit and push reviewed changes to GitHub while preserving unrelated pending modifications.

## Data Protection
- Preserve existing business records and pending local code changes.
- Back up before database migrations and verify restore behavior.
- Do not clear app data, uninstall the app casually, overwrite the SQLite database, or deploy untested Firestore rules.
- Never commit service-account credentials, private keys, passwords, or other secrets.
- Keep Firebase on the Spark plan unless a separate decision is made to change plans.
- Do not allow client applications to assign themselves owner or staff roles.
- Treat Firebase initialization, authentication, cloud backup, and live synchronization as separate capabilities.
- Do not describe a feature as completed until it has been tested and verified.
