# BusinessDash Development Log

This file records important development milestones and decisions.

---

## 2026-08-15

### Project Foundation

BusinessDash Flutter project created.

Flutter environment was already configured and working.

Initial Git repository created.

Initial commit:

`chore: create BusinessDash Flutter project`

Branch changed to:

`main`

GitHub repository:

`Moses361/business_dash`

---

### Dashboard

Created the first BusinessDash dashboard.

Initial dashboard included:

- Business Dashboard heading
- Products count
- Today's Sales
- Low Stock
- View Products action

Created reusable dashboard card widget.

Commit:

`feat: improve dashboard cards`

---

### Application Navigation

Created main application navigation.

Current main screens:

- Dashboard
- Products
- Sales

Implemented Flutter Material 3 `NavigationBar`.

---

### Products Screen

Created initial Products screen.

Added:

- Search field
- Category filter chips
- Product count
- Product cards
- Stock display
- Low-stock indication
- Selling prices
- Add Product button

Created reusable:

`ProductCard`

---

### Add Product

Created Add Product screen.

Fields:

- Product name
- Category
- Buying price
- Selling price
- Stock quantity

Added form validation.

Added navigation from Products to Add Product.

Current Save Product action only displays a success message.

It does not yet save to persistent storage.

---

## Current Architecture

Current main structure:

lib/
  main.dart
  screens/
  widgets/
  models/
  services/
  database/
  repositories/

The architecture is being introduced gradually for learning purposes.

---

## Important Decision

We will build the UI and business workflow progressively, but we
will now begin replacing sample/static data with real local data.

The application is intended to work offline.

---

## Next Development Session

### Product Database

Next tasks:

1. Create Product model
2. Choose SQLite package
3. Create database service
4. Create products table
5. Create repository
6. Connect Add Product form
7. Load products from database
8. Display real products

---

## Development Philosophy

BusinessDash is both:

1. A learning project
2. A reusable foundation for future client applications

The application should remain understandable to a beginner while
following good software-engineering practices.

Features should be implemented in small Git checkpoints.

---

### 2026-08-15 (UI Polish)

- Polished Dashboard, Products and Sales screens with improved Material 3 styling.
- Reworked hero cards, stat cards, product cards and quick action cards.
- Applied a cohesive green theme across the app and improved navigation bar styling.
- Added `google_fonts` and applied `Poppins` typography for a professional look.
- Replaced nonstandard color helpers with standard `.withOpacity()` calls.
- Updated README and project documentation for clarity.

Commit:

`chore: polish UI, update theme and docs`

---

## 2026-10-27 — Android and Multi-Device Testing Milestone

### Confirmed Progress

- Installed and launched the Flutter application on a physical Samsung SM A155F device.
- Confirmed the owner sign-in flow works with the tested account.
- Confirmed existing product and business data load after sign-in.
- Confirmed dashboard and sidebar navigation work.
- Exercised product and sales workflows.
- Tested business data synchronization across devices; the developer reports that products and sales behaved as expected.
- Observed successful synchronization/upload status messages during testing.
- Preserved the milestone in GitHub commit `adde6c5`.

### Existing Behavior Preserved

The pending-access screen remains intentional. A newly used device or an account without an approved Veroon profile or staff membership must follow the existing authentication and approval flow.

Branding and image improvements should not change the underlying access-control behavior.

### Remaining Verification

- Replace the generic bag icon with the approved Veroon branding and supplied image.
- Verify all intended images across sign-in, pending-access, and other relevant screens.
- Test synchronization for expenses, edits, deletions, and additional account scenarios.
- Verify owner/staff membership and role-based permissions.
- Test restoration from a known backup.
- Complete release APK installation and final client acceptance tests.
- Plan the separate web application milestone.

### Documentation Accuracy

Successful status messages and developer workflow tests are recorded as observed results. They are not a substitute for formal backup-restoration, authorization, or release-acceptance testing.
