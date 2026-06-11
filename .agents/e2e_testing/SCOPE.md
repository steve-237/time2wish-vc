# Scope: E2E Testing Track

## Architecture
- Opaque-box E2E test suite covering Time2Wish Admin Panel.
- Setup test runner (Cypress).
- Test cases organized by Tiers 1-4.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Setup Test Framework | Install Cypress, configure base URL and API endpoints. Create skeleton directories. | none | DONE |
| 2 | Tier 1 Tests | Implement 25 Feature Coverage tests. | M1 | IN_PROGRESS |
| 3 | Tier 2 Tests | Implement 25 Boundary & Corner Case tests. | M2 | PLANNED |
| 4 | Tier 3 Tests | Implement pairwise Cross-Feature tests. | M3 | PLANNED |
| 5 | Tier 4 Tests | Implement 5 Real-World Scenarios. | M4 | PLANNED |
| 6 | Publish TEST_READY.md | Create TEST_READY.md. | M5 | PLANNED |

## Interface Contracts
### Angular Frontend ↔ Cypress
- Tests interact with the UI elements.
- Tests use opaque-box assertions.

### Spring Boot Backend ↔ Cypress API Tests
- API tests interact with `/api/admin/*`.
- Token-based auth simulated or obtained via login API.
