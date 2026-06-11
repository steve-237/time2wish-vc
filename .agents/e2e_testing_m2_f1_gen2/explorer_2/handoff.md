# Handoff Report: Cypress Test Strategy for F1 (Admin Auth (RBAC))

## 1. Observation
- `TEST_INFRA.md` specifies that feature F1 "Admin Auth (RBAC)" requires 5 Tier-1 test cases. Tests must be opaque-box, requirement-driven, and independent of implementation design.
- `PROJECT.md` details that the frontend uses Angular with a separate layout dedicated to administration, protected by Route Guards. Access control relies on `ROLE_USER` and `ROLE_ADMIN` permissions.
- `SCOPE.md` directs the test placement to `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` and notes the use of standard Cypress UI navigation (`cy.visit('/login')`, `cy.visit('/admin')`).

## 2. Logic Chain
To fulfill the requirement of 5 opaque-box, tier-1 tests covering Role-Based Access Control (RBAC), we must test the boundary conditions of authentication (logged in vs. logged out) and authorization (admin vs. regular user) purely through UI behavior:
1. **Admin Authorization (Happy Path)**: Ensures a valid admin account can access the protected route.
2. **Standard User Authorization (Negative Path)**: Ensures a valid regular account is restricted from the admin route, validating the `ROLE_ADMIN` vs `ROLE_USER` separation.
3. **Unauthenticated Access (Negative Path)**: Ensures the route is completely sealed off from guests (no active session).
4. **RBAC UI Visibility**: Ensures the frontend dynamically adapts to the user's role by hiding/showing admin controls.
5. **Session Revocation**: Ensures that logging out properly destroys the admin session, preventing back-button or direct-link exploits.

## 3. Caveats
- The exact UI selectors (e.g., `data-cy="admin-link"`) and redirection paths (e.g., whether unauthorized users are redirected to `/dashboard`, `/login`, or `/403`) are not defined in the provided docs. The implementer will need to adapt the selectors and expected URLs to the actual frontend implementation.
- The strategy assumes the existence of pre-seeded test accounts (one Admin, one Standard User) or the ability to use `cy.intercept` to mock the backend auth responses.

## 4. Conclusion
Recommend implementing the following 5 test cases in `tier1_f1_admin_auth.cy.js`:

1. **Test Case 1: Admin Authorization (Happy Path)**
   - *Action*: Log in with `ROLE_ADMIN` credentials.
   - *Action*: Navigate to the `/admin` URL.
   - *Expected*: The admin dashboard loads successfully and the URL remains `/admin`.
   
2. **Test Case 2: Standard User Access Blocked (Negative)**
   - *Action*: Log in with standard `ROLE_USER` credentials.
   - *Action*: Attempt to navigate directly to `/admin`.
   - *Expected*: Access is denied, and the user is redirected away (e.g., back to `/dashboard` or an access denied page).
   
3. **Test Case 3: Unauthenticated Access Blocked (Negative)**
   - *Action*: Without authenticating (clear cookies/session).
   - *Action*: Attempt to navigate directly to `/admin`.
   - *Expected*: Access is denied, and the user is redirected to the `/login` route.
   
4. **Test Case 4: RBAC UI Element Visibility**
   - *Action*: Log in with `ROLE_ADMIN` credentials and verify that admin-specific UI elements (e.g., Admin Panel link) are visible in the navigation menu.
   - *Action*: Log out, then log in with `ROLE_USER` credentials.
   - *Expected*: The admin-specific UI elements are entirely absent from the DOM.
   
5. **Test Case 5: Session Revocation / Logout Security**
   - *Action*: Log in as an Admin and navigate to `/admin`.
   - *Action*: Trigger the application's logout functionality.
   - *Action*: Attempt to navigate to `/admin` again.
   - *Expected*: Access is denied, and the user is redirected to `/login`, proving the session is securely terminated.

## 5. Verification Method
- **Inspection**: Review `e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js` to confirm it contains exactly these 5 `it()` blocks and implements the described logic using Cypress commands (`cy.visit()`, `cy.get()`, `cy.url().should()`).
- **Execution**: Run the E2E tests against the application using `npx cypress run --spec e2e/cypress/e2e/tier1_features/tier1_f1_admin_auth.cy.js`. All 5 tests should pass when the application and backend are running locally.
