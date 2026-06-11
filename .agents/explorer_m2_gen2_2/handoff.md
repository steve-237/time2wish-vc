# Handoff Report: Milestone 2 Backend Admin APIs

## Observation

1. **Routing and Security:** `WebSecurityConfig.java` already secures `/api/admin/**` with `.hasRole("ADMIN")`. The `AdminController.java` exists but only has a `/test` endpoint.
2. **Missing DTOs:** The `app.time2wish.dto` package lacks DTOs for admin responses. Specifically, there is no `AdminUserDto` (to safely expose user data without passwords), `StatsResponse` (for dashboard stats), or `AdminPasswordUpdateRequest` (for admin-forced password resets without requiring the `currentPassword`).
3. **Data Constraints:** The `User` entity is referenced by `RefreshToken`, `MessageTemplate`, and `Birthday`. `Birthday` has an `@ElementCollection` for `interests`. 
4. **Repositories:** `UserRepository` exists but `BirthdayRepository` only has `findByUserAndIsDeletedFalse`. To safely delete a user's data via JPA without foreign key errors, we need to find all related records (including soft-deleted birthdays) before deleting them, or rely on a soft-delete strategy for the `User` itself (`status = "DELETED"`).

## Logic Chain

1. **Service Layer:** To keep `AdminController` clean and separate from `UserDetailsServiceImpl` (which handles authentication), a new `AdminService` should be created. This service will orchestrate fetching users, deleting users, updating passwords, and gathering stats.
2. **DTO Creation:** To fulfill the frontend contracts (`GET /api/admin/users`, `GET /api/admin/stats`, etc.), we must create `AdminUserDto` to map `User` entities, `StatsResponse` to aggregate counts, and `AdminPasswordUpdateRequest` with just a `newPassword` field.
3. **User Deletion Strategy:** 
   - *Option A (Hard Delete):* Must fetch and delete all dependent records first. For this, `List<Birthday> findByUser(User user);` must be added to `BirthdayRepository`. We can then call `repository.deleteAll()` for templates, birthdays, and refresh tokens before deleting the user.
   - *Option B (Soft Delete):* The `User` model has a `status` field (default `ACTIVE`). The service could simply set `user.setStatus("DELETED")`.
4. **Stats Aggregation:** The simplest implementation for stats is utilizing the `count()` methods inherited from `JpaRepository` on `UserRepository` and `BirthdayRepository`.

## Caveats

- I have outlined a hard-delete approach in the conclusion as the default, but if the project prefers soft-deleting users, the implementer can just update `user.setStatus("DELETED")` instead.
- The `StatsResponse` is assumed to require basic metrics (total users, total birthdays). If the frontend requires complex time-series data, the `AdminService` and repositories will need custom `@Query` methods.
- I assumed the password modification endpoint is `PUT` based on the scope document (`PUT/PATCH`). 

## Conclusion

The implementer should execute the following plan:

1. **Create DTOs (`app/time2wish/dto/`):**
   - `AdminUserDto`: `id`, `email`, `fullName`, `role`, `status`, `createdAt`, `lastLoginAt`.
   - `StatsResponse`: `totalUsers` (long), `totalBirthdays` (long).
   - `AdminPasswordUpdateRequest`: `newPassword` (String).
2. **Modify Repositories:**
   - In `BirthdayRepository.java`, add: `List<Birthday> findByUser(User user);`
   - (`TemplateRepository` already has `findByUser`).
3. **Create `AdminService.java`:**
   - Methods: `List<AdminUserDto> getAllUsers()`, `void deleteUser(Long id)`, `void updateUserPassword(Long id, String newPassword)`, `StatsResponse getStats()`.
   - For `deleteUser(id)`: Find user, use `deleteAll(findByUser(user))` on `RefreshTokenRepository`, `BirthdayRepository`, and `TemplateRepository`, then `userRepository.delete(user)`.
   - For `updateUserPassword(id, newPassword)`: Use `passwordEncoder.encode(newPassword)` and save.
4. **Update `AdminController.java`:**
   - Inject `AdminService`.
   - Add `@GetMapping("/users")` -> returns list of users.
   - Add `@DeleteMapping("/users/{id}")` -> calls delete logic.
   - Add `@PutMapping("/users/{id}/password")` -> calls password update logic.
   - Add `@GetMapping("/stats")` -> returns stats.

## Verification Method

1. Build the backend: Run `./mvnw clean compile` to ensure no syntax errors.
2. Run tests: Run `./mvnw test` to ensure existing and new tests pass.
3. API Verification: Start the backend and use Postman or cURL to hit the new endpoints (`GET /api/admin/users`, `GET /api/admin/stats`) with an Admin JWT token to verify HTTP 200 responses and correct JSON structures. Check that deleting a user removes or disables their records correctly.
