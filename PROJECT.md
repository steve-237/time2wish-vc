# Project: Time2Wish Admin Panel

## Architecture
- **Frontend Web & Mobile Native**: Angular 21 application + Ionic Capacitor 7 targeting Android (`frontend/android`) and iOS (`frontend/ios`).
- **Flutter Native Mobile Subsystem**: Standalone Flutter 3.44+ application (`mobile_flutter/`).
- **Backend**: Spring Boot 3 with Spring Security. Role-based access control.
- **Integration**: Secure REST API under `/api/*` protected by JWT tokens.

## Code Layout
- Frontend (Web & Capacitor Native): `d:\formations_personnelles\time2wish-ai\frontend`
- Flutter Mobile App: `d:\formations_personnelles\time2wish-ai\mobile_flutter`
- Backend API: `d:\formations_personnelles\time2wish-ai\backend`

## Interface Contracts
### Angular Frontend ↔ Spring Boot Backend
- Authentication header: usually `Authorization: Bearer <token>`
- `/api/admin/users` (GET, DELETE)
- `/api/admin/users/{id}/password` (PUT/PATCH)
- `/api/admin/stats` (GET)
