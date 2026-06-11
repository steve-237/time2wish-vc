# Handoff: F1 Admin Auth (RBAC) Cypress Test Strategy

## Observation
1. `TEST_INFRA.md` specifies that tests must be opaque-box, requirement-driven, and Tier 1 features like "Admin Auth (RBAC)" require 5 tier-1 tests.
2. `SCOPE.md` targets the file `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` and requires testing Admin Auth (RBAC) using test accounts or mocks.
3. `PROJECT.md` notes that the Frontend Admin Layout is a separate Angular layout dedicated to administration and should be protected by Route Guards.
4. `PROJECT.md` identifies backend roles as `ROLE_USER` and `ROLE_ADMIN`.

## Logic Chain
1. To thoroughly validate the `Admin Auth (RBAC)` requirements from an opaque-box perspective, we must test both positive (allowed) and negative (denied) access scenarios across different user states: Administrator, Standard User, and Guest (Unauthenticated).
2. **Test 1 (Admin Happy Path)**: Verify that an administrator can successfully log in and gain access to the `/admin` route and admin layout. This confirms `ROLE_ADMIN` functionality.
3. **Test 2 (Standard User Login)**: Verify that a standard user can log in but does not see admin navigation links. This confirms UI-level role segregation.
4. **Test 3 (Standard User RBAC Denial)**: Verify that a logged-in standard user (`ROLE_USER`) is denied access when attempting direct URL navigation to `/admin`. This tests the frontend Route Guards for unauthorized roles.
5. **Test 4 (Guest Access Denial)**: Verify that an unauthenticated user attempting to directly access `/admin` is properly intercepted and redirected to `/login`. This tests Route Guards for unauthenticated states.
6. **Test 5 (Session Termination / Logout)**: Verify that after an administrator logs out, their session is invalidated, and subsequent attempts to visit `/admin` result in a denial or redirection to `/login`.

## Caveats
- The exact test implementation will depend on how the login logic is mocked (using Cypress `cy.intercept()` for API responses vs. real seeded test accounts). It is recommended to use `cy.intercept()` to mock backend responses if a dedicated E2E test database with predefined accounts isn't set up.
- The default redirection path for unauthorized access (e.g., 403 vs redirect to home) may need adjustment depending on the actual frontend implementation.

## Conclusion
The test strategy defines 5 required tier-1 tests verifying RBAC for the admin panel. These cover Admin access, Standard User limitations (both UI and direct routing), Guest redirection, and Logout security. The implementer should write these test cases in `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js`.

## Verification Method
Once implemented, the tests can be verified by running the Cypress test suite against the target spec file.
Command to verify:
`cd frontend && npx cypress run --spec e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` (or from wherever the Cypress project root is defined). All 5 tests must pass.
