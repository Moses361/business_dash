
# BusinessDash - Project Context

## Project Name

BusinessDash

## Purpose

BusinessDash is a learning project and reusable foundation for building
offline business-management applications for small businesses in Kenya.

The long-term goal is to create customizable applications for businesses
such as:

- Motorcycle spare-parts shops
- Agrovet shops
- Hardware shops
- Electronics shops
- General retail businesses

The first potential client operates a motorcycle spare-parts
store/workshop and an agrovet.

The application will initially focus on inventory, sales and basic
business totals.

---

## Current Stage

We are currently building the BusinessDash MVP.

The visual application shell and initial product-management interface
have been created.

We are now moving from static/sample data toward real persistent
local data using SQLite.

---

## Development Environment

- Operating System: Windows 11 Pro 64-bit
- Computer: Lenovo ThinkPad T480s
- Development tools: VS Code + Git Bash
- Flutter: 3.47.0 stable
- Dart: 3.13.0
- Android SDK: 36
- Android API: 36
- Primary test phone: OPPO CPH2819
- Android: 16 / API 36

A separate Flutter test project exists and must remain separate:

C:\Development\flutter_test_app

That project is only a reference/testing project and must not be
converted into the client application.

---

## Project Location

C:\Development\business_dash

## GitHub Repository

https://github.com/Moses361/business_dash

## Git Branch

main

---

## Technology

- Flutter
- Dart
- Android
- SQLite/local offline database
- Git
- GitHub
- VS Code

A database package such as sqflite or drift will be selected when we
implement the local database.

---

## Architecture

The project should not place the entire application inside main.dart.

Current structure:

lib/
  main.dart
  screens/
  widgets/
  models/
  services/
  database/
  repositories/

We are introducing the architecture gradually so that the developer
can understand the purpose of each layer.

---

## Completed Features

### Project foundation

- Flutter project created
- Git initialized
- Initial project commit created
- Branch changed to main
- GitHub repository connected
- Flutter successfully builds the application
- Application successfully runs on the OPPO test device

### Application shell

- BusinessDash application theme
- Material 3
- Bottom navigation
- Dashboard screen
- Products screen
- Sales screen

### Dashboard

- Business Dashboard heading
- Products summary card
- Today's Sales summary card
- Low Stock summary card
- View Products navigation

### Products UI

- Product search field
- Category filter chips
- Product cards
- Product name
- Product category
- Stock display
- Low-stock indication
- Selling price
- Add Product button

### Add Product UI

- Product name field
- Category dropdown
- Buying price field
- Selling price field
- Stock quantity field
- Form validation
- Save Product action
- Navigation from Products to Add Product

---

## Current Limitation

Products are currently sample/static data.

The Add Product form currently demonstrates the UI and validation
workflow but does not yet permanently save products.

The next major milestone is to introduce a Product model and SQLite
local database.

---

## Next Feature

### Real Product Storage

Implement:

1. Product model
2. Local SQLite database
3. Product table
4. Product repository
5. Save product
6. Load products
7. Display real products
8. Edit product
9. Delete product
10. Search real products

---

## Planned Feature Roadmap

### Phase 1 - Product Management

- Product model
- SQLite database
- Add product
- View products
- Edit product
- Delete product
- Search products
- Categories
- Low-stock detection

### Phase 2 - Sales

- Record sale
- Select product
- Enter quantity
- Calculate sale total
- Reduce stock automatically
- Sales history
- Daily sales total

### Phase 3 - Dashboard

- Real product count
- Real sales total
- Real low-stock count
- Daily sales
- Basic business statistics

### Phase 4 - Business Features

- Expenses
- Profit calculations
- Customers
- Suppliers
- Purchases
- Stock adjustments
- Reports
- Date filtering

### Phase 5 - Advanced Features

- PDF/CSV export
- Backup/restore
- User accounts
- Roles/permissions
- Multiple devices
- Cloud synchronization
- Notifications
- Advanced analytics

---

## Important Design Principle

BusinessDash should remain generic enough to be reused for different
small businesses.

Avoid hard-coding the application specifically for one client's
business.

The eventual client application can be customized from the BusinessDash
foundation.

---

## Important Development Principle

The developer is learning Flutter and Dart.

Every major feature should therefore be explained clearly:

- What we are building
- Why we are building it
- Where the code belongs
- What the code does
- How to run it
- How to test it
- How to commit it

Do not replace the entire project when an error occurs unless necessary.

Diagnose errors step-by-step.

---

## Current Known Issues

- Products are still sample/static data.
- Add Product does not yet save to SQLite.
- Search is currently UI-only.
- Category filters are currently UI-only.
- Edit and Delete are not implemented.
- Sales are currently sample/static data.
- The Redmi/Xiaomi test phone with model 24117RN76G currently refuses
  ADB installation with INSTALL_FAILED_USER_RESTRICTED.
- OPPO CPH2819 remains the primary development/test device.

---

## Current Git Checkpoint

The project should be committed whenever a meaningful feature is
completed.

Preferred commit style:

- chore: create BusinessDash Flutter project
- feat: add dashboard
- feat: add products screen
- feat: add product form
- feat: add local database
- feat: add sales
- feat: calculate stock
- feat: add reports
