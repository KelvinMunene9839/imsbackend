# System Design Documentation

## Overview
This system is an Investor Management System (IMS) consisting of a Flutter frontend application and a Node.js backend API server. The system supports authentication for admin and investor users, and provides various features such as asset management, interest penalties, reports, and dashboards.

## Architecture

```
+----------------+          HTTP REST API          +----------------+
|                |  <-------------------------->  |                |
|  Flutter App   |                               |  Node.js Express |
|  (Frontend)    |                               |  Backend API    |
|                |                               |                |
+----------------+                               +----------------+
         |                                                |
         |                                                |
         |                                                |
         |                                                |
         v                                                v
+----------------+                               +----------------+
|                |                               |                |
|  User Devices  |                               |  Database      |
|  (Mobile, Web) |                               |  (SQL)         |
|                |                               |                |
+----------------+                               +----------------+
```

## Components

### Frontend (Flutter)
- Developed using Flutter framework.
- Provides UI screens for admin and investor login, dashboards, and management features.
- Uses HTTP package to communicate with backend REST API.
- Configured with backend base URL for API requests.
- Handles user input, authentication, and navigation.

### Backend (Node.js Express)
- REST API server built with Express.js.
- Routes organized by feature modules: auth, admin, investor, assets, penalties, reports, etc.
- Uses middleware for CORS, JSON parsing, and authentication.
- Connects to a SQL database for persistent storage.
- Listens on configurable port (default 4000).
- Provides endpoints for login, registration, data retrieval, and updates.

### Database
- SQL database (schema defined in ims_schema.sql).
- Stores user credentials, assets, penalties, reports, and other domain data.
- Accessed by backend via database client.

## API Design
- Base URL: `http://<backend_host>:<port>/api`
- Authentication endpoints:
  - POST `/auth/admin/login`
  - POST `/auth/investor/login`
  - POST `/auth/investor/register`
- Admin endpoints under `/api/admin` for managing assets, investors, penalties, reports.
- Investor endpoints under `/api/investor` for investor-specific data.
- JSON used for request and response payloads.

## Security
- Authentication implemented via login endpoints.
- CORS enabled globally on backend to allow frontend access.
- Passwords and sensitive data handled securely (assumed).
- Further security measures (e.g., JWT, HTTPS) to be implemented as needed.

## Deployment
- Backend server runs on a machine accessible by frontend devices.
- Backend listens on port 4000 by default.
- Flutter app configured with backend base URL.
- Network and firewall settings must allow communication between frontend and backend.

## Summary
This system provides a modular, scalable architecture for managing investors and related financial data, with a Flutter frontend and Node.js backend communicating over REST APIs.
