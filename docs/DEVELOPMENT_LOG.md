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

## Next steps
1. Review the documentation changes.
2. Commit and push only the two documentation files.
3. Inspect the stash without applying it.
4. Design secure business membership and Firestore rules.
5. Plan a safe SQLite migration.
6. Implement and test synchronization in small stages.

## Data protection
Preserve existing business records. Back up before migrations. Do not clear app data, overwrite the database, or deploy untested rules. Never commit credentials or private keys.