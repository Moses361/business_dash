# Veroon Project Handover

## Project
- Flutter business management app: Veroon
- Project folder: `/c/Development/business_dash`
- Firebase project: `veroon-business-dashboard`
- Local database: SQLite, schema version 8
- Git branch: `main`
- Latest database groundwork commit: `18e915c`

## Existing features
- Dashboard, products, inventory, sales, expenses, and reports
- Firebase initialization
- Firebase Authentication and Firestore dependencies
- Local SQLite repositories
- Cloud backup snapshots (not live synchronization)
- Database synchronization metadata for products, sales, and expenses

## Database changes completed
- Upgraded SQLite schema from version 7 to version 8.
- Added `sync_id`, `sync_status`, `updated_at`, and `deleted_at` metadata to products, sales, and expenses.
- Added indexes for synchronization IDs and statuses.
- Backfilled existing records with synchronization metadata.
- New records use UUIDs and begin in a pending-sync state.
- Product and expense deletion uses soft-delete tracking.
- Sale and stock changes use transactions and validate product availability and stock.
- Product updates cannot modify records already marked as deleted.
- JSON backup restore supports database versions 7 and 8, validates records, checks duplicate IDs, and creates a safety export before restoration.

## Verification
- Dart formatting completed for the four changed Dart files.
- `flutter test` passed with 2 tests.
- `flutter analyze` reported 16 warnings/informational issues and no errors.
- These results describe the latest recorded run; rerun checks after further changes.

## Current status and limitations
- Live multi-device synchronization is not implemented.
- The new metadata is groundwork for future synchronization, not proof of successful cloud sync.
- Automatic cloud upload/download, offline retry handling, conflict resolution, and deletion propagation still need implementation and testing.
- Existing Firestore rules were previously inspected and reported to deny general live-sync access.
- The inspected login flow may create Authentication users without Firestore profiles.
- The owner profile was reported to contain `businessId: veroon_main_business`.
- A Git safety stash exists: `Safety checkpoint before Veroon cloud sync`.

## Live-sync plan
1. Inspect the saved stash without applying it.
2. Confirm the Authentication and business-profile flow.
3. Design secure business membership and Firestore permissions.
4. Review and test Firestore rules before deployment.
5. Implement safe upload/download, offline retries, conflict handling, and deletion tracking.
6. Prevent duplicate sales and double stock deductions.
7. Test with two devices and verify consistency.
8. Preserve existing SQLite records and cloud-backup functionality throughout.

## Safety rules
- Never clear or replace the existing database as a shortcut.
- Back up and verify data before migrations or restores.
- Preserve the existing cloud-backup feature.
- Never deploy untested Firestore rules.
- Do not apply or pop the stash blindly.
- Never commit credentials or private keys.
- Record only verified test results and distinguish database preparation from working cloud synchronization.

## Next action
Review the documentation diffs, commit only the two documentation files, and push the documentation update. Then inspect the safety stash and continue live-sync implementation in small, tested steps.

## Current Status — 2026-10-24

### Firebase Authentication and Registration
- Firebase project: `veroon-business-dashboard`.
- Firebase initialization and Android configuration are in place.
- `AuthGate` checks authentication and the user's approved Firestore role.
- The owner registration screen now includes a business-name field.
- New registrations submit a pending request to `accessRequests/{uid}`.
- Firestore rules have been edited locally to restrict registration requests and prevent client-side role assignment.
- Firestore rules have not yet been deployed.
- Registration and approval have not yet been verified against the live Firebase project.

### Build and Testing
- `flutter pub get` completed successfully.
- `flutter analyze` reported 13 existing or outstanding lint issues, with no new registration-screen issues reported.
- `git diff --check` reported no whitespace errors.
- Android debug APK build and runtime testing are pending confirmation.

### Architecture and Safety
- Products, sales, and expenses currently use local SQLite.
- Database synchronization metadata has been added, but live cloud synchronization is not implemented or verified.
- Administrator approval remains a manual process.
- Business-level data isolation and staff permissions need further design.
- Preserve existing SQLite records and unrelated pending code changes.
- Keep Firebase on the Spark plan unless a separate decision is made to change plans.

### Immediate Next Steps
1. Confirm the Android debug build result.
2. Test registration with a dedicated test account.
3. Verify the pending request in Firestore.
4. Test that unapproved accounts cannot access the dashboard.
5. Review and deploy Firestore rules only after testing.
6. Implement a secure administrator approval process.
7. Continue planning multi-business isolation and live synchronization.
