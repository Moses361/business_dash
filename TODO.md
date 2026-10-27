# Veroon Business Dashboard — TODO

This checklist tracks remaining work from the current Android milestone. Mark items complete only after verification.

## Current Priority — Branding

- [ ] Obtain the approved Veroon/owner image.
- [ ] Replace the generic bag icon on the sign-in screen.
- [ ] Replace the generic icon on the pending-access screen.
- [ ] Review branding on the dashboard, sidebar, and other relevant screens.
- [ ] Rebuild and verify the updated application on a physical device.
- [ ] Preserve the existing authentication and pending-access behavior.

## Multi-Device Synchronization

- [x] Configure Firebase Authentication and Firestore.
- [x] Deploy Firestore security rules.
- [x] Exercise product and sales workflows across devices.
- [ ] Verify product creation, editing, and deletion across devices.
- [ ] Verify sales and stock changes across devices.
- [ ] Verify expenses and other synchronized record types.
- [ ] Verify that devices belong to the same authorized business.
- [ ] Test offline changes and subsequent synchronization.
- [ ] Test duplicate prevention and synchronization conflicts.
- [ ] Verify that unauthorized users cannot access another business's data.

## Authentication and Staff Access

- [x] Exercise owner sign-in.
- [x] Confirm the pending-access flow appears when approval is required.
- [ ] Review owner account provisioning.
- [ ] Verify staff creation or invitation flow.
- [ ] Verify staff membership and approval.
- [ ] Verify role-specific permissions.
- [ ] Test sign-out and sign-in on a second device.
- [ ] Confirm that business membership cannot be bypassed.

## Backup and Restoration

- [x] Exercise the backup workflow and observe its reported status.
- [ ] Create a known backup containing test data.
- [ ] Restore the backup in a controlled test.
- [ ] Verify products, sales, expenses, and relevant relationships after restoration.
- [ ] Document backup location, limitations, and recovery procedure.

## Business Workflows and Reports

- [x] Exercise product and sales workflows.
- [ ] Verify stock reduction and insufficient-stock handling.
- [ ] Verify sales totals and profit calculations.
- [ ] Verify expense totals and net profit calculations.
- [ ] Test report date ranges and filtering.
- [ ] Test PDF or CSV exports, where implemented.
- [ ] Test empty states, loading states, and error handling.

## Release Readiness

- [ ] Run `flutter analyze` and review warnings.
- [ ] Run available automated tests.
- [ ] Test the latest build on a physical Android device.
- [ ] Verify offline behavior and recovery after reconnecting.
- [ ] Complete backup-restoration and security checks.
- [ ] Build the release APK.
- [ ] Install and test the release APK independently of debug mode.
- [ ] Complete client acceptance testing.
- [ ] Document installation and account setup instructions.

## Future Milestone — Web Application

- [ ] Audit current application screens and business logic for web compatibility.
- [ ] Identify Android-specific dependencies and APIs.
- [ ] Define the web authentication and business-membership experience.
- [ ] Adapt responsive layouts for desktop and mobile browsers.
- [ ] Validate database, synchronization, and report behavior on web.
- [ ] Deploy a staging version and complete client testing.

## Project Hygiene

- [ ] Keep secrets and credentials out of Git.
- [ ] Preserve known-working commits before significant changes.
- [ ] Keep project documentation aligned with the implementation.
