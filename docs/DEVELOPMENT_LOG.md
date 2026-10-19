# Veroon Development Log

## 2026-10-17 — Firebase setup
- Firebase project: `veroon-business-dashboard`.
- Android Firebase configuration generated.
- Firebase initialization added to `lib/main.dart`.
- Earlier analyzer run reportedly had no errors and 18 warnings/informational notices.
- Android USB/ADB detection was unreliable.
- Browser launch with `flutter run -d chrome` was proposed; success is unconfirmed.

## 2026-10-18 — Live-sync planning
- Firebase initialization and authentication routing were inspected.
- Products, sales, and expenses use local SQLite.
- Cloud backup stores snapshots, not live synchronization.
- Inspected Firestore rules do not yet permit shared live sync.
- A saved Git stash protects earlier branding and authentication-related changes.
- Live sync has not been implemented or verified.

## 2026-10-19 — Database groundwork for cloud sync
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

## Next steps
1. Inspect the saved safety stash without applying it.
2. Review Firebase Authentication, business membership, and Firestore access requirements.
3. Design and test secure Firestore rules before deployment.
4. Plan a safe local-database migration and preserve existing records.
5. Implement synchronization in small stages, including upload/download, offline retries, conflict handling, and deletion propagation.
6. Prevent duplicate sales and double stock deductions during retries.
7. Test with two devices and verify data consistency before claiming live sync is working.

## Data protection
Preserve existing business records. Back up before migrations and verify restore behavior. Do not clear app data, overwrite the database, or deploy untested rules. Never commit credentials or private keys.
