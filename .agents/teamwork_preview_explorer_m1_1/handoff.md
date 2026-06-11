# Handoff Report: E2E Test Framework Setup (Milestone M1)

## Observation
- The project requires Cypress to be set up as an opaque-box E2E testing tool for both Frontend (Angular) and Backend (Spring Boot).
- The designated folder for E2E tests is `d:\formations_personnelles\time2wish-ai\e2e`, which currently does not exist.
- According to `TEST_INFRA.md`, a specific directory structure under `e2e/cypress/e2e` is required for organizing tests into 4 tiers.
- Review of `backend/src/main/resources/application.yml` reveals the backend server runs on port 8081 (`server.port: 8081`).
- Review of `frontend/package.json` indicates a standard Angular environment, implying the frontend runs on the default port 4200.

## Logic Chain
1. Because `e2e` doesn't exist, we must initialize a new Node project there (`npm init -y`) and install `cypress` as a dev dependency.
2. Since Cypress acts as an opaque-box tester interacting with both frontend and backend independently, we must configure `cypress.config.js` or `cypress.config.ts` with `baseUrl` pointing to `http://localhost:4200` (for UI tests) and an environment variable `apiUrl` pointing to `http://localhost:8081/api` or `http://localhost:8081/api/admin` (for direct API tests/setup).
3. `TEST_INFRA.md` requires 4 specific tier directories. We must create `tier1_features`, `tier2_boundaries`, `tier3_interactions`, and `tier4_scenarios` inside `e2e/cypress/e2e/`.
4. Adding an empty `.keep` file in each tier directory will allow git to track them even if they contain no specs initially.

## Caveats
- I did not verify if the frontend specifically serves at `/` or another base href, but Angular defaults to `/`.
- The exact API prefix might be `/api/admin` or just `/api`. It's recommended to set `apiUrl` to `http://localhost:8081` and append specific paths in the Cypress specs.
- The `e2e` project might require `typescript` if `cypress.config.ts` is used. Using `cypress.config.js` avoids additional setup overhead.

## Conclusion
The implementer must:
1. Create the `e2e` directory and run `npm init -y`.
2. Run `npm install cypress --save-dev` inside `e2e`.
3. Create `cypress.config.js` with `baseUrl: 'http://localhost:4200'` and `env.apiUrl: 'http://localhost:8081'`.
4. Create the required 4 tier directories (`tier1_features`, `tier2_boundaries`, `tier3_interactions`, `tier4_scenarios`) inside `e2e/cypress/e2e/` and add a `.keep` file to each.

## Verification Method
1. Navigate to the `e2e` directory.
2. Run `npx cypress verify` to ensure Cypress installed correctly.
3. Run `ls cypress/e2e` and verify all 4 tier directories are present.
4. Run `npx cypress run` to check if Cypress can parse the config without errors (it will complain about no tests, which is expected and fine for M1).
