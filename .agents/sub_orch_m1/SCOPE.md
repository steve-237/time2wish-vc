# Scope: Backend Admin Roles

## Architecture
- Backend: Spring Boot 3 with Spring Security. Role-based access control.
- Integration: Secure REST API under `/api/admin/*` protected by tokens.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend Admin Roles | Implement `ROLE_USER` and `ROLE_ADMIN` in Spring Security. Secure `/api/admin/*`. | none | IN_PROGRESS |

## Interface Contracts
### Angular Frontend ↔ Spring Boot Backend
- Authentication header: usually `Authorization: Bearer <token>`
- Requires `ROLE_ADMIN` for `/api/admin/**` endpoints.
