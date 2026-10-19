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
