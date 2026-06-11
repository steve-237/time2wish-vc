# Handoff Report: E2E Testing M1 Implementation Strategy

## 1. Observation
- `TEST_INFRA.md` requires: "Cypress specs in `d:\formations_personnelles\time2wish-ai\e2e`" and a specific directory layout inside `e2e/cypress/e2e/` (tier1_features, tier2_boundaries, tier3_interactions, tier4_scenarios).
- `e2e_testing/SCOPE.md` specifies Milestone 1: "Install Cypress, configure base URL and API endpoints. Create skeleton directories."
- `frontend/angular.json` uses the default Angular CLI build/serve, which binds to `localhost:4200`.
- `backend/src/main/resources/application.yml` specifies `server.port: 8081`.
- Directory `e2e` currently does not exist. Cypress is not installed in `frontend/package.json`.

## 2. Logic Chain
- Since `TEST_INFRA.md` points to an `e2e` directory separate from `frontend`, we must initialize a new Node project in the `e2e` folder.
- Cypress configuration needs a `baseUrl` for frontend assertions and an environment variable (`apiUrl`) for API interactions.
- Frontend port 4200 -> `baseUrl: 'http://localhost:4200'`.
- Backend port 8081 -> `env.apiUrl: 'http://localhost:8081'`.
- To satisfy the directory skeleton requirement, the four tier directories must be explicitly created.
- TypeScript is typically preferred with Angular projects, so installing `typescript` alongside `cypress` is recommended.

## 3. Caveats
- I did not test running Cypress myself since I am a read-only agent.
- The `tsconfig.json` for Cypress might need specific compiler options to avoid conflicting with the frontend workspace, though putting it inside the `e2e` directory isolates it.
- If an admin-specific base URL is preferred (e.g. `http://localhost:4200/admin`), it could be adjusted later. `http://localhost:4200` is safer as the root `baseUrl`.

## 4. Conclusion
To implement Milestone M1, the following concrete actions must be performed:
1. Create directory `d:\formations_personnelles\time2wish-ai\e2e`.
2. Inside `e2e`, run `npm init -y` and `npm install -D cypress typescript`.
3. Create `d:\formations_personnelles\time2wish-ai\e2e\cypress.config.ts` with:
   ```typescript
   import { defineConfig } from 'cypress';

   export default defineConfig({
     e2e: {
       baseUrl: 'http://localhost:4200',
       env: {
         apiUrl: 'http://localhost:8081'
       },
       specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
       supportFile: false,
       setupNodeEvents(on, config) {
         // implement node event listeners here
       },
     },
   });
   ```
4. Create the following directories inside `e2e`:
   - `cypress/e2e/tier1_features`
   - `cypress/e2e/tier2_boundaries`
   - `cypress/e2e/tier3_interactions`
   - `cypress/e2e/tier4_scenarios`

## 5. Verification Method
- **Commands**: 
  - Change directory to `e2e` and run `npx cypress verify` to ensure Cypress installed successfully.
  - Run `npx cypress run` (it may report 0 specs found, which is expected, but should not throw a configuration error).
- **Files to Inspect**: Verify the presence of `cypress.config.ts` and the `cypress/e2e` tier subdirectories inside the `e2e` folder.
