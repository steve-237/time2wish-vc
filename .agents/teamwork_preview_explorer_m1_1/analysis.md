# Milestone M1 Analysis: Setup Test Framework

## Overview
This analysis outlines the required steps to set up the E2E Test Framework (Cypress) for the Time2Wish Admin Panel as specified in Milestone M1.

## Architecture Context
The project is split into:
- **Frontend**: Angular application located in `frontend/`. Default port is 4200.
- **Backend**: Spring Boot application located in `backend/`. Its port is configured to 8081 (from `application.yml`).
- **E2E Testing**: Cypress will be used as an opaque-box tester. According to `TEST_INFRA.md`, the E2E tests should be stored in a new top-level directory called `e2e/`.

## Requirements Checklist (M1)
1. **Install Cypress**: Requires creating a new Node project in `e2e/` and installing the `cypress` npm package.
2. **Configure base URL and API endpoints**:
   - `baseUrl` for Cypress should point to the frontend: `http://localhost:4200`
   - API endpoint reference should point to the backend: `http://localhost:8081/api`
3. **Create skeleton directories for Tiers 1-4**:
   - `e2e/cypress/e2e/tier1_features/`
   - `e2e/cypress/e2e/tier2_boundaries/`
   - `e2e/cypress/e2e/tier3_interactions/`
   - `e2e/cypress/e2e/tier4_scenarios/`

## Implementation Strategy
To fulfill M1, the implementing agent should execute the following non-intrusive setup:

1. **Directory Creation**:
   Create the directory `d:\formations_personnelles\time2wish-ai\e2e`.

2. **Project Initialization**:
   Inside `e2e`, run `npm init -y` to generate a `package.json` file.
   Run `npm install cypress --save-dev` to install Cypress.
   Update `package.json` to add Cypress execution scripts (e.g., `"cypress:open": "cypress open"`, `"cypress:run": "cypress run"`).

3. **Cypress Configuration**:
   Create a `cypress.config.ts` (or `.js`) inside the `e2e` directory with the following structure:
   ```javascript
   const { defineConfig } = require('cypress')

   module.exports = defineConfig({
     e2e: {
       baseUrl: 'http://localhost:4200',
       env: {
         apiUrl: 'http://localhost:8081/api/admin'
       },
       setupNodeEvents(on, config) {
         // implement node event listeners here
       },
     },
   })
   ```

4. **Skeleton Directories**:
   Create the required subdirectories in `e2e/cypress/e2e/`. To ensure they are tracked by git, it's recommended to place a `.keep` file or a dummy `example.cy.js` inside each.
