# Handoff Report: Milestone M1 (Setup Test Framework)

## 1. Observation
- The directory `d:\formations_personnelles\time2wish-ai\e2e` does not exist.
- `TEST_INFRA.md` specifies that Cypress specs must live in `d:\formations_personnelles\time2wish-ai\e2e` and provides a required directory layout: `e2e/cypress/e2e/tier1_features/`, `tier2_boundaries/`, `tier3_interactions/`, and `tier4_scenarios/`.
- `SCOPE.md` defines M1 as: "Install Cypress, configure base URL and API endpoints. Create skeleton directories."
- Searching the `frontend` folder shows that the Angular app runs on `http://localhost:4200` (`frontend/README.md`) and the backend API is served at `http://localhost:8081/api` (`frontend/src/app/services/auth.service.ts`).
- `PROJECT.md` specifies the Admin backend APIs will be served under `/api/admin/*`.
- `frontend/package.json` does not include Cypress, confirming it must be configured as a standalone package.

## 2. Logic Chain
1. To satisfy `TEST_INFRA.md`, the E2E framework must be instantiated as a new standalone Node project in the `e2e` folder at the root level, rather than tightly coupled into the `frontend` Angular project.
2. Cypress needs to be installed as a devDependency in this new `e2e` project.
3. For Cypress tests to interact with the UI, the `baseUrl` in Cypress configuration must match the frontend development server, which is `http://localhost:4200`.
4. For Cypress tests to easily interact with the backend API, an environment variable `apiUrl` should be configured to `http://localhost:8081/api/admin`.
5. The four tier-specific folders must be created inside `e2e/cypress/e2e/` to fulfill the "Create skeleton directories" requirement of M1.

## 3. Caveats
- Setting up a standalone `e2e` project means that the E2E test runner won't automatically boot the `frontend` and `backend` servers. The user or CI/CD pipeline will need to ensure `http://localhost:4200` and `http://localhost:8081` are running prior to executing tests.
- TypeScript support is recommended (given the Angular frontend) but not strictly explicitly required by the prompt, though standard practice is to use `.ts` files for Cypress these days. We suggest adding `typescript` to devDependencies.

## 4. Conclusion
The implementation agent should execute the following sequence:
1. Create the `e2e` directory at the project root.
2. Run `npm init -y` inside `e2e`.
3. Run `npm install --save-dev cypress typescript` inside `e2e`.
4. Create a `cypress.config.ts` (or `.js`) in the `e2e` folder with:
   - `e2e.baseUrl = 'http://localhost:4200'`
   - `env.apiUrl = 'http://localhost:8081/api/admin'`
5. Create the four requested skeleton directories: `cypress/e2e/tier1_features`, `cypress/e2e/tier2_boundaries`, `cypress/e2e/tier3_interactions`, `cypress/e2e/tier4_scenarios`.
6. Add helper scripts `"cypress:open": "cypress open"` and `"cypress:run": "cypress run"` to `e2e/package.json`.

## 5. Verification Method
1. Verify the `e2e` folder exists and contains a valid `package.json` with `cypress` listed under `devDependencies`.
2. Inspect `e2e/cypress.config.ts` to ensure `baseUrl` is `http://localhost:4200` and `apiUrl` is `http://localhost:8081/api/admin`.
3. List the contents of `e2e/cypress/e2e/` and confirm `tier1_features`, `tier2_boundaries`, `tier3_interactions`, and `tier4_scenarios` exist.
4. Execute `cd e2e && npx cypress verify` or `npm run cypress:run` (expecting a run failure on missing tests, but the framework itself should launch).
