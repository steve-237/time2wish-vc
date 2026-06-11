# Analysis: E2E Testing Track - Milestone M1

## 1. Goal Overview
Milestone M1 requires setting up the E2E Test Framework:
- Install Cypress.
- Configure base URL (frontend) and API endpoints (backend).
- Create skeleton directories for test organization (Tiers 1-4).

## 2. Project Layout & Configurations
- **Location**: Based on `TEST_INFRA.md`, the E2E tests should reside in a separate directory at the project root: `d:\formations_personnelles\time2wish-ai\e2e`.
- **Frontend App**: Angular 21 application. From `angular.json`, the standard development server port is `4200`. The frontend base URL for tests should be `http://localhost:4200`.
- **Backend API**: Spring Boot 3 application. From `backend/src/main/resources/application.yml`, the server runs on port `8081`. The API base URL for E2E API tests should be `http://localhost:8081`.
- **Existing Setup**: A search confirmed no Cypress configuration currently exists in the workspace. The `frontend` project uses Vitest for unit tests.

## 3. Implementation Strategy
To fulfill M1 without modifying any existing application code, a new Node.js project must be initialized in the `e2e` folder.

### Step-by-Step Guide
1. **Initialize Directory & Node Project**:
   - Create the directory `e2e` at the project root.
   - Run `npm init -y` inside `e2e` to create `package.json`.
   - Run `npm install -D cypress typescript` inside `e2e`.

2. **Configure Cypress**:
   - Create a `cypress.config.ts` (or `.js`) file in the `e2e` folder.
   - Configure the `e2e` block:
     - `baseUrl`: `'http://localhost:4200'`
     - `env`: `{ apiUrl: 'http://localhost:8081/api/admin' }`
     - `specPattern`: `'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}'`

3. **Create Skeleton Directories**:
   - Create the following folders inside `e2e`:
     - `cypress/e2e/tier1_features`
     - `cypress/e2e/tier2_boundaries`
     - `cypress/e2e/tier3_interactions`
     - `cypress/e2e/tier4_scenarios`
   - Create `cypress/support` and `cypress/fixtures` if Cypress doesn't automatically scaffold them when run. (Running `npx cypress open` or scaffolding manually).

4. **TypeScript Setup (Optional but recommended)**:
   - Create `tsconfig.json` in `e2e` extending Cypress types to ensure IDE autocompletion works.

## 4. Verification
The implementation can be verified by running `npx cypress run` (even if it reports 0 tests found, it should run without configuration errors) and verifying the directory tree matches the requirements.
