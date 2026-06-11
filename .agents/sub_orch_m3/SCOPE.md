# Project: Time2Wish Admin Panel
# Scope: M3 - Frontend Admin Layout

## Architecture
- **Frontend**: Angular 21 application.
- We need to create a distinct layout component for the administration panel.
- We need an Angular Route Guard to protect admin routes (verifying the user has ROLE_ADMIN).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 3 | Frontend Admin Layout | Separate Angular layout dedicated to administration + Route Guards. | M1 | IN_PROGRESS |

## Interface Contracts
### Angular Frontend ↔ Spring Boot Backend
- The admin guard should verify the user's role, presumably by reading the JWT token or fetching user info that has `ROLE_ADMIN`.
- Unauthenticated or non-admin users should be redirected or blocked (403).
