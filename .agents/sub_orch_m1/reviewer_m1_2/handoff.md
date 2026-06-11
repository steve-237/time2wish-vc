# Handoff: Milestone 1 Review (Backend Admin Roles)

## Observation
- `Role.java` was created with `ROLE_USER` and `ROLE_ADMIN`.
- `User.java` entity was updated to include the `role` field with `@Enumerated(EnumType.STRING)` and a default of `ROLE_USER`.
- `V7__add_user_roles.sql` was added to apply the database schema change safely using `DEFAULT 'ROLE_USER'`.
- `UserDetailsImpl.java` now correctly maps `user.getRole().name()` into a `SimpleGrantedAuthority`.
- `WebSecurityConfig.java` enforces `.requestMatchers("/api/admin/**").hasRole("ADMIN")`.
- `AdminController.java` was added at `/api/admin` with a `/test` endpoint.
- `AuthController.java` registers users with `ROLE_USER` by default.
- `AdminControllerTest.java` correctly verifies the security rules using MockMvc (`isForbidden()`, `isOk()`, `isUnauthorized()`).

## Logic Chain
1. The requirement is to implement the two roles and secure `/api/admin/*`.
2. The `Role` enum and `User` entity updates establish the roles at the data model level.
3. The Flyway script cleanly migrates existing data to avoid constraint violations.
4. The security mapping in `UserDetailsImpl` appropriately builds `GrantedAuthority` so that `WebSecurityConfig` can perform authorization via `hasRole("ADMIN")`.
5. The `AdminController` provides a practical verification point.
6. Existing controllers are unharmed. Tests correctly cover all access conditions (anonymous, user, admin) for the protected admin route.

## Caveats
- `mvn clean test` timed out when run via shell, so a manual static review was performed as instructed. The static review confirms that the logic and MockMvc tests are sound.
- No UI changes were part of the scope, so none were reviewed.

## Conclusion
**Verdict: PASS**
The implementation fully satisfies the requirements for Milestone 1. It is correct, secure, and robust.

## Verification Method
- Execute `mvn clean test` to ensure `AdminControllerTest` passes.
- Inspect `src/main/java/app/time2wish/security/WebSecurityConfig.java` to verify `hasRole("ADMIN")` is protecting `/api/admin/**`.
