# Handoff Report: Cypress Tier-1 Tests for F1 (Admin Auth RBAC)

## 1. Observation
- `TEST_INFRA.md` specifies that tests must be opaque-box, requirement-driven, and follow a Category-Partition + BVA methodology. It requires 5 Tier-1 test cases for Feature 1 (Admin Auth (RBAC)).
- `SCOPE.md` identifies the target file as `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js`. It mentions that tests should mock or use test accounts. The frontend runs on `http://localhost:4200`. It specifies testing routes like `/login` and `/admin`.
- `PROJECT.md` details that the backend uses `ROLE_USER` and `ROLE_ADMIN` in Spring Security and that the Angular frontend has a distinct separate layout for the Admin interface. Admin endpoints are protected under `/api/admin/*`.

## 2. Logic Chain
Based on the observations, we must define 5 black-box test cases that validate the RBAC constraints without coupling to the implementation:
- **Test 1 (Admin Happy Path)**: Verify that a valid `ROLE_ADMIN` account can authenticate via `/login`, access the `/admin` route, and see the admin layout.
- **Test 2 (User Boundary/Negative Path)**: Verify that a valid `ROLE_USER` account can authenticate but is restricted from accessing the `/admin` route (redirected away or shown access denied).
- **Test 3 (Unauthenticated Access)**: Verify that attempting to visit the `/admin` route without an active session automatically redirects the user to `/login`.
- **Test 4 (Admin Sub-Route Protection)**: Verify that a valid `ROLE_ADMIN` account can navigate seamlessly to admin sub-routes (e.g., `/admin/users` or `/admin/stats`).
- **Test 5 (Session Termination)**: Verify that an admin who logs out loses access to the `/admin` routes, enforcing session closure.

## 3. Caveats
- Since this is an opaque-box test strategy, specific DOM selectors (e.g., `[data-cy=submit-btn]`) and test credentials must be determined by the implementer based on the actual HTML structure and test environment setup.
- The exact redirect behavior for unauthorized access (e.g., redirecting a `ROLE_USER` from `/admin` to `/dashboard` vs. showing an "Access Denied" page) depends on the Angular routing configuration and should be asserted accordingly.

## 4. Conclusion
I recommend implementing the following 5 tests in `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js`:

1.  **Should successfully log in as an Admin and navigate to the admin dashboard.**
    - Action: Visit `/login`, enter admin credentials, submit.
    - Assert: URL includes `/admin`, admin layout/sidebar is visible.
2.  **Should prevent a standard User from accessing the admin area.**
    - Action: Visit `/login`, enter standard user credentials, submit. Attempt to visit `/admin` directly.
    - Assert: User is redirected away from `/admin` (e.g., to `/dashboard`) or shown an unauthorized message. Admin controls are not present.
3.  **Should redirect an unauthenticated user to the login page when accessing an admin route.**
    - Action: Clear session/cookies, visit `/admin`.
    - Assert: URL is `/login`.
4.  **Should allow an Admin to access protected sub-routes (e.g., `/admin/users`).**
    - Action: Log in as admin, navigate to `/admin/users` (either by clicking a sidebar link or direct URL).
    - Assert: URL includes `/admin/users`, correct view is rendered.
5.  **Should restrict access to admin routes after an Admin logs out.**
    - Action: Log in as admin, click logout button. Attempt to visit `/admin`.
    - Assert: User is on `/login`, and the `/admin` visit is blocked.

## 5. Verification Method
- Ensure the test suite file `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` contains `it` blocks for each of the 5 scenarios described above.
- Execute the tests using Cypress (e.g., `npx cypress run --spec e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js`). All 5 tests should pass.
