# Milestone 2 Backend Security & Test Strategy Handoff

## Observation
1. **Security Configuration**: `d:\formations_personnelles\time2wish-ai\backend\src\main\java\app\time2wish\security\WebSecurityConfig.java` enforces global security on admin paths using `.requestMatchers("/api/admin/**").hasRole("ADMIN")` (line 68). The `@EnableMethodSecurity` annotation is also present, allowing method-level security.
2. **Admin Controller**: `d:\formations_personnelles\time2wish-ai\backend\src\main\java\app\time2wish\controller\AdminController.java` maps to `/api/admin`, but lacks an explicit `@PreAuthorize` annotation for defense-in-depth and currently only contains a `/test` endpoint.
3. **Data Transfer Objects (DTOs)**: `d:\formations_personnelles\time2wish-ai\backend\src\main\java\app\time2wish\dto` does not contain an `AdminUserResponse` (needed to hide password hashes when listing users), `AdminPasswordUpdateRequest` (needed because the admin does not know the user's `currentPassword`), or `AdminStatsResponse`.
4. **Integration Tests**: `d:\formations_personnelles\time2wish-ai\backend\src\test\java\app\time2wish\controller\AdminControllerTest.java` contains basic access tests for `/api/admin/test` with `@WithMockUser` for `USER`, `ADMIN`, and Anonymous. It lacks tests for the four new endpoints required by M2 (`GET /users`, `DELETE /users/{id}`, `PUT /users/{id}/password`, `GET /stats`).

## Logic Chain
- Because `/api/admin/**` is protected in `WebSecurityConfig`, unauthorized access is generally prevented. However, relying solely on path-based security is fragile; adding `@PreAuthorize("hasRole('ADMIN')")` on `AdminController` provides robust method-level security as a secondary layer.
- Because `User` entity contains a `password` field without `@JsonIgnore` (observed in `User.java`), returning raw `User` objects from `GET /api/admin/users` would leak password hashes. Thus, a dedicated `AdminUserResponse` DTO is required.
- Because an admin modifying a user's password won't possess the `currentPassword`, the existing `PasswordUpdateRequest` DTO is insufficient. A new `AdminPasswordUpdateRequest` containing only `newPassword` is necessary.
- Because the M2 Scope requires four new endpoints, comprehensive integration tests must be written to verify both the business logic and the security constraints (ADMIN access allowed, USER/Anonymous denied) for each endpoint.

## Caveats
- I did not explore if a dedicated `AdminService` should be created vs placing the logic directly in `UserService`. This architectural choice is left to the implementer, though an `AdminService` is recommended to keep admin-specific logic isolated.
- The `AdminStatsResponse` structure is undefined in the project spec; I am assuming it will initially consist of basic counts (e.g., total users, total birthdays).
- Admin self-deletion logic is not explicitly defined. The implementer should consider whether an admin can delete their own account.

## Conclusion
The backend requires the following implementation steps for M2:
1. Add `@PreAuthorize("hasRole('ADMIN')")` at the class level in `AdminController.java`.
2. Create DTOs: `AdminUserResponse`, `AdminPasswordUpdateRequest`, and `AdminStatsResponse`.
3. Implement the 4 required endpoints in `AdminController.java` (using a service class for business logic):
   - `GET /api/admin/users`
   - `DELETE /api/admin/users/{id}`
   - `PUT /api/admin/users/{id}/password`
   - `GET /api/admin/stats`
4. Update `AdminControllerTest.java` to include test methods for each new endpoint, verifying 3 scenarios per endpoint:
   - `@WithMockUser(roles = "ADMIN")` -> Expect success (200/204).
   - `@WithMockUser(roles = "USER")` -> Expect `status().isForbidden()`.
   - Anonymous -> Expect `status().isUnauthorized()`.

## Verification Method
1. Ensure the code compiles: `./mvnw clean compile` (or `mvn clean compile`).
2. Run the tests to confirm functionality and security constraints: `./mvnw test -Dtest=AdminControllerTest`.
3. Inspect `AdminController.java` for `@PreAuthorize` and ensure endpoints use the new DTOs (not returning the `User` entity directly).
