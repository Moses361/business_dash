# Veroon Client Handover Roadmap

## Goal
Deliver a reliable Android APK for a business owner, with approved staff
accounts, secure roles, live multi-device synchronization, and tested recovery.

## Milestones and estimates

| # | Milestone | Estimate | Priority |
|---|---|---|---|
| 1 | Audit existing code, database, and uncommitted changes | 0.5-1 working day | Critical |
| 2 | Staff self-registration, pending status, owner approval/rejection | 1-2 working days | Critical |
| 3 | Role permissions, business isolation, Firebase security rules | 2-4 working days | Critical |
| 4 | Near-real-time synchronization across authorized devices | 3-7 working days | Critical |
| 5 | Cloud backup listing, download, validation, and safe restoration | 1-2 working days | High |
| 6 | Regression, security, offline/reconnection, and multi-device tests | 1-2 working days | Critical |
| 7 | Signed release APK, installation test, documentation, and handover | 1 working day | Final |

**Estimated total:** 9.5-19 working days, approximately 2-4 weeks.
This is a planning estimate and may change after the code audit.

## Required behavior

### Staff accounts
- Staff can register with email and password.
- New accounts remain pending until approved by the business owner.
- Pending or rejected users cannot access business records.
- The owner can approve, reject, and revoke staff access.
- Staff cannot grant themselves roles or permissions.

### Roles and security
- Define permissions for owner, manager (if required), and sales staff.
- Enforce authorization in Firebase security rules and trusted data-access logic,
  not only by hiding app screens.
- Isolate every business's records from other businesses.
- Test unauthorized reads, writes, role changes, and revoked accounts.

### Live synchronization
- Authorized devices receive remote changes within seconds when online,
  subject to connectivity and service availability.
- Handle concurrent updates, duplicate sale submissions, stock integrity,
  offline changes, reconnection, and retry behavior.
- Define conflict-resolution rules before enabling offline writes.
- Verify that synchronization does not expose data to unauthorized users.

### Backup and recovery
- List available cloud backups and show dates and record counts.
- Allow the owner to select and download a backup.
- Validate backup format and records before restoration.
- Create a safety backup before replacing local data.
- Test interrupted uploads, failed restores, and recovery without data loss.

## Release acceptance checklist
- [ ] Staff registration and owner approval tested.
- [ ] Roles and business-level data isolation tested.
- [ ] Two or more authorized devices synchronize correctly.
- [ ] Sales and stock totals remain correct under concurrent use.
- [ ] Offline and reconnection behavior tested.
- [ ] Cloud backup download and restoration verified.
- [ ] Critical errors resolved and Flutter analysis reviewed.
- [ ] Signed release APK installed and tested on Android.
- [ ] Setup, usage, backup, and recovery instructions prepared.
- [ ] Source changes reviewed, committed, and pushed to GitHub.
- [ ] Client access, account ownership, and support responsibilities confirmed.

## Current verified baseline
- Firebase owner sign-in works.
- Manual cloud backup completed successfully.
- A reported backup contained 3 products, 3 sales, and 1 expense.
- Cloud restore, staff self-registration, and live synchronization still require
  implementation and end-to-end verification.

## Handover rule
Do not declare a milestone complete until its acceptance tests pass.
Preserve existing source changes and verified backups throughout development.
