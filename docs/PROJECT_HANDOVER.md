# Veroon Project Handover

## Project
- Flutter business management app: Veroon
- Project folder: `/c/Development/business_dash`
- Firebase project: `veroon-business-dashboard`
- Local database: SQLite, reported schema version 7
- Git branch: `main`

## Existing features
- Dashboard, products, inventory, sales, expenses, reports
- Firebase initialization
- Firebase Authentication and Firestore dependencies
- Local SQLite repositories
- Cloud backup snapshots (not live synchronization)

## Current status
- Live multi-device synchronization is not implemented.
- Existing Firestore rules allow owner backup access but deny general live-sync access.
- The inspected login flow may create Authentication users without Firestore profiles.
- The owner profile was reported to contain `businessId: veroon_main_business`.
- A Git safety stash exists: `Safety checkpoint before Veroon cloud sync`.

## Live-sync plan
1. Inspect the saved stash without applying it.
2. Design secure business membership and permissions.
3. Add stable record IDs while preserving existing SQLite records.
4. Implement safe upload/download, offline retries, conflict handling, and deletion tracking.
5. Prevent duplicate sales and double stock deductions.
6. Test with two devices before claiming success.

## Safety rules
- Never clear or replace the existing database as a shortcut.
- Back up and verify data before migrations.
- Preserve the existing cloud-backup feature.
- Never deploy untested Firestore rules.
- Do not apply or pop the stash blindly.
- Record only verified test results.

## Next action
Review Git status and both documentation diffs, commit only the intended documentation files, then continue live-sync implementation in small steps.