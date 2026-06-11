# Analysis: Setup Test Framework (Milestone M1)

## Summary
The goal of Milestone M1 is to set up the Cypress test framework for the E2E Testing Track. The tests should be placed in a separate, standalone `e2e` directory at the root of the workspace, rather than inside the `frontend` application, according to the architectural layout defined in `TEST_INFRA.md`.

## Key Findings
1. **Directory Structure:**
   - The workspace currently has `frontend/` and `backend/` directories, but no `e2e/` directory.
   - `TEST_INFRA.md` requires the following path format: `d:\formations_personnelles\time2wish-ai\e2e`.
   - Inside `e2e`, there should be four subdirectories under `cypress/e2e/`:
     - `tier1_features/`
     - `tier2_boundaries/`
     - `tier3_interactions/`
     - `tier4_scenarios/`

2. **Network/API Configuration:**
   - A `grep_search` across the frontend repository reveals that it expects to run on `http://localhost:4200` (`frontend/README.md`).
   - The frontend communicates with the backend via `http://localhost:8081/api` (e.g., in `frontend/src/app/services/auth.service.ts`).
   - `PROJECT.md` dictates that the newly built admin endpoints will be hosted under `/api/admin/*`.
   - Therefore, Cypress needs `baseUrl: 'http://localhost:4200'` for frontend E2E and an environment variable for the API base (`apiUrl: 'http://localhost:8081/api/admin'`).

3. **Current Dependencies:**
   - A check of `frontend/package.json` shows no Cypress presence (it uses `vitest` for unit testing).
   - This confirms Cypress must be initialized from scratch in the new `e2e` folder.

## Implementation Strategy
1. Create a new directory at `d:\formations_personnelles\time2wish-ai\e2e`.
2. Navigate into `e2e` and initialize a Node.js project (`npm init -y`).
3. Install Cypress (and optionally TypeScript) via `npm install cypress typescript --save-dev`.
4. Create the Cypress configuration file `cypress.config.ts` containing the required base URL and API endpoints configuration.
5. Create the required skeleton directory structure:
   - `e2e/cypress/e2e/tier1_features`
   - `e2e/cypress/e2e/tier2_boundaries`
   - `e2e/cypress/e2e/tier3_interactions`
   - `e2e/cypress/e2e/tier4_scenarios`
6. Add `cypress run` and `cypress open` scripts to `e2e/package.json`.
