# Project: Time2Wish Admin Panel

## Architecture
- **Frontend**: Angular 21 application. Distinct separate layout for the Admin interface.
- **Backend**: Spring Boot 3 with Spring Security. Role-based access control.
- **Integration**: Secure REST API under `/api/admin/*` protected by tokens (JWT/session depending on existing implementation).

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend Admin Roles | Implement `ROLE_USER` and `ROLE_ADMIN` in Spring Security. Secure `/api/admin/*`. | none | DONE |
| 2 | Backend Admin APIs | Endpoints for listing users, stats, delete user, modify user password. | M1 | IN_PROGRESS |
| 3 | Frontend Admin Layout | Separate Angular layout dedicated to administration + Route Guards. | M1 | IN_PROGRESS |
| 4 | Frontend Admin Views | Dashboard (Stats), User list, Delete/Modify password actions. | M2, M3 | PLANNED |
| 5 | E2E Tests Pass | 100% of the E2E test suite must pass (Implementation Track). | M4 | PLANNED |

## Code Layout
- Frontend: `d:\formations_personnelles\time2wish-ai\frontend`
- Backend: `d:\formations_personnelles\time2wish-ai\backend`

## Interface Contracts
### Angular Frontend ↔ Spring Boot Backend
- Authentication header: usually `Authorization: Bearer <token>`
- `/api/admin/users` (GET, DELETE)
- `/api/admin/users/{id}/password` (PUT/PATCH)
- `/api/admin/stats` (GET)
