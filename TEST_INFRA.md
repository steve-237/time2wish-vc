# E2E Test Infra: Time2Wish Admin Panel

## Test Philosophy
- Opaque-box, requirement-driven. No dependency on implementation design.
- Methodology: Category-Partition + BVA + Pairwise + Workload Testing.

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Admin Auth (RBAC) | ORIGINAL_REQUEST R2 | 5      | 5      | ✓      |
| 2 | List Users | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |
| 3 | Global Stats | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |
| 4 | Block/Delete User | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |
| 5 | Modify User Password | ORIGINAL_REQUEST R3 | 5      | 5      | ✓      |

## Test Architecture
- Test runner: Cypress or Playwright for E2E frontend, REST Assured or Supertest for E2E API. (We'll use Cypress since Angular is the frontend, and it can do API testing as well).
- Test case format: Cypress specs in `d:\formations_personnelles\time2wish-ai\e2e`.
- Directory layout:
  - `e2e/cypress/e2e/tier1_features/`
  - `e2e/cypress/e2e/tier2_boundaries/`
  - `e2e/cypress/e2e/tier3_interactions/`
  - `e2e/cypress/e2e/tier4_scenarios/`

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Admin logs in, views stats, lists users, deletes a malicious user, resets a forgotten password, and logs out. | F1, F2, F3, F4, F5 | High     |

## Coverage Thresholds
- Tier 1: ≥5 per feature (Total 25)
- Tier 2: ≥5 per feature (Total 25)
- Tier 3: pairwise coverage of major feature interactions
- Tier 4: ≥5 realistic application scenarios
