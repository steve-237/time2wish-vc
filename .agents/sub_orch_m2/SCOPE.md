# Scope: Backend Admin APIs (Milestone 2)

## Architecture
- Module/package boundaries, data flow, shared interfaces
- Target: `/api/admin/*` paths
- Controllers, Services, Repositories for User management and Stats.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend Admin APIs | Endpoints for listing users, stats, delete user, modify user password. | none | IN_PROGRESS |

## Interface Contracts
### Angular Frontend ↔ Spring Boot Backend
- Authentication header: `Authorization: Bearer <token>`
- `/api/admin/users` (GET, DELETE)
- `/api/admin/users/{id}/password` (PUT/PATCH)
- `/api/admin/stats` (GET)
