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

## Dashboard UI and Analytics Improvements

**Goal:** Deliver a polished, modern, responsive Veroon dashboard that looks professional on Android phones and larger screens, while displaying accurate business information from real records.

### Dashboard visual design
- [ ] Preserve the Veroon brand, approved logo, and consistent visual identity across the dashboard, sidebar, login, and pending-access screens.
- [ ] Refine spacing, typography, colors, card shapes, alignment, and visual hierarchy for a professional business application.
- [ ] Keep the layout responsive on narrow phones, larger phones, tablets, and desktop-sized screens.
- [ ] Keep the dashboard readable, uncluttered, and easy to navigate.
- [ ] Ensure long currency amounts and business names fit without clipping or overflowing.
- [ ] Provide consistent loading, empty, error, and retry states.
- [ ] Preserve existing authentication, authorization, navigation, and business workflows.

### Dashboard summary cards
- [ ] Refine the prominent net-profit hero card, including clear profit/loss presentation.
- [ ] Display sales revenue, gross profit, and expenses in compact summary cards.
- [ ] Make reporting periods explicit so users understand whether figures are for today, a selected period, or all time.
- [ ] Verify every summary against the underlying business records and report calculations.
- [ ] Format Kenyan currency consistently using KSh and sensible decimal precision.

### Charts and business analytics
- [ ] Add a sales trend chart using actual sales records, grouped by day or another suitable interval.
- [ ] Add a profit trend chart using verified revenue, cost, and expense calculations.
- [ ] Add an expenses trend or category breakdown where the available data supports it.
- [ ] Add a best-selling products chart or ranking based on real quantities sold or sales value.
- [ ] Consider a sales-versus-expenses comparison where the data and definitions make the comparison meaningful.
- [ ] Add useful reporting-period filters, such as today, 7 days, 30 days, and a custom date range where practical.
- [ ] Ensure charts respond correctly to period changes and refreshes.
- [ ] Show clear labels, dates, currency units, legends where useful, and helpful empty states.
- [ ] Do not invent, hardcode, or display sample values as if they were actual business results.
- [ ] Check chart totals against existing reports and repository/database queries.
- [ ] Keep charts performant on Android and usable on small screens.

### Inventory and daily operations
- [ ] Improve low-stock alerts and make affected products easy to identify.
- [ ] Show useful stock information without implying that stock is available when it is not.
- [ ] Improve the recent-transactions summary where the existing data supports it.
- [ ] Keep quick actions for common tasks, including adding a sale and managing products.
- [ ] Make important alerts and actions easy to reach without overcrowding the dashboard.

### Data integrity and implementation
- [ ] Inspect existing models, SQLite repositories, report calculations, and synchronization services before adding new dashboard data logic.
- [ ] Reuse existing business logic instead of creating conflicting duplicate calculations.
- [ ] Define and verify the meaning of revenue, cost of goods sold, gross profit, expenses, and net profit.
- [ ] Ensure date filtering handles date boundaries consistently.
- [ ] Confirm charts and summary cards refresh after relevant records change.
- [ ] Preserve existing SQLite data, backup and restoration behavior, and synchronization functionality.
- [ ] Never weaken authentication or Firestore security rules to support dashboard features.

### Dashboard acceptance checks
- [ ] Test the dashboard on the connected Android phone.
- [ ] Check narrow-screen layouts, long amounts, and overflow behavior.
- [ ] Compare dashboard figures and chart values with independently verified records and reports.
- [ ] Test empty data, loading, errors, refresh, and unavailable connectivity.
- [ ] Run targeted Flutter analysis and relevant automated tests.
- [ ] Recheck existing product, sales, expense, and staff workflows after UI changes.
- [ ] Record verified results and outstanding issues in the project documentation.

### Recommended implementation order
1. Complete the current code audit and preserve a safe Git checkpoint.
2. Finish dashboard responsiveness, branding, and layout polish.
3. Verify existing financial calculations and reporting-period behavior.
4. Implement charts using verified real business data.
5. Improve inventory alerts, recent transactions, and quick actions.
6. Test on the physical Android device and run regression checks.
7. Continue the separate synchronization, security, backup-restoration, and release-readiness milestones.

**Design direction:** A premium, clean Veroon business dashboard with a prominent net-profit hero, compact KPI cards, readable analytics charts, clear inventory alerts, and quick actions. Prioritize clarity and trustworthy numbers over decorative graphics.

**Completion rule:** Mark each item complete only after the relevant implementation and verification have succeeded.
