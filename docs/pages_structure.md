# Pages Structure Documentation

This document describes the structure and organization of the pages in the Flutter frontend application of the Investor Management System (IMS) project.

## Directory Structure

```
frontend/lib/pages/
├── admin_dashboard.dart
├── admin_login_screen.dart
├── investor_dashboard.dart
├── login_screen.dart
├── admin/
│   ├── assets_tab.dart
│   ├── contribution_trends_chart.dart
│   ├── interest_rates_tab.dart
│   ├── investors_tab.dart
│   ├── penalties_tab.dart
│   ├── pending_transactions_tab.dart
│   └── reports_tab.dart
```

## Description

- **admin_dashboard.dart**  
  The main dashboard page for admin users, providing an overview and navigation to various admin features.

- **admin_login_screen.dart**  
  The login screen for admin users to authenticate and access admin functionalities.

- **investor_dashboard.dart**  
  The main dashboard page for investor users, showing personalized investment information and options.

- **login_screen.dart**  
  The login screen for general users or investors to authenticate.

- **admin/**  
  This directory contains various tabs and components used within the admin dashboard, each representing a specific feature or data view:
  - **assets_tab.dart**: Manages and displays asset-related information.
  - **contribution_trends_chart.dart**: Visualizes contribution trends with charts.
  - **interest_rates_tab.dart**: Displays and manages interest rates.
  - **investors_tab.dart**: Lists and manages investor information.
  - **penalties_tab.dart**: Shows penalties and related data.
  - **pending_transactions_tab.dart**: Displays pending transactions for review.
  - **reports_tab.dart**: Provides reporting features and data exports.

## Navigation Flow

- Users start at the appropriate login screen (`admin_login_screen.dart` or `login_screen.dart`).
- Upon successful login, users are directed to their respective dashboards (`admin_dashboard.dart` or `investor_dashboard.dart`).
- Admin users can navigate through various tabs within the admin dashboard, each implemented as separate Dart files under the `admin/` directory.

## Summary

The pages are organized to separate admin and investor functionalities clearly, with modular components for each feature within the admin dashboard. This structure promotes maintainability and scalability of the frontend application.
