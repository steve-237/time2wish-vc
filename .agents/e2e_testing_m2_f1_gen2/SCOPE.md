# Scope: M2_F1

## Architecture
- e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js
- Opaque-box frontend tests targeting the Angular app using Cypress.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Tier 1 Tests for F1 | Implement 5 Cypress Feature Coverage tests for F1 in `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` | none | IN_PROGRESS |

## Interface Contracts
### Cypress ↔ Angular App
- Frontend runs on `http://localhost:4200`
- Tests should mock or use test accounts to test Admin Auth (RBAC).
- `cy.visit('/login')`, `cy.visit('/admin')`, etc.
