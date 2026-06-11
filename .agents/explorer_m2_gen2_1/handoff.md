# Handoff Report: Milestone 2 Backend Admin APIs

**Summary**: The investigation identified `AdminController.java` as the correct entry point. To fulfill Milestone 2, the implementer needs to expand this controller, introduce an `AdminService` for business logic, handle cascading deletes manually, and create DTOs to avoid exposing sensitive data.

## 1. Observation
- The project is a Spring Boot 3 application.
- The `WebSecurityConfig.java:68` already restricts `/api/admin/**` to users with `ROLE_ADMIN`.
- `d:\formations_personnelles\time2wish-ai\backend\src\main\java\app\time2wish\controller\AdminController.java` exists and is annotated with `@RequestMapping("/api/admin")`, currently containing only a `/test` endpoint.
- There is no `UserService` or `AdminService` handling administrative logic.
- The `app.time2wish.model.User` entity does not have `@JsonIgnore` on the `password` field (line 22). Returning it directly in API responses would expose the password hash.
- The `User` entity lacks `@OneToMany` cascading mappings. `RefreshToken`, `Birthday`, and `MessageTemplate` entities hold foreign keys referencing `user_id`.
- Repositories exist for all entities, but `BirthdayRepository` only has `findByUserAndIsDeletedFalse(User user)`. 

## 2. Logic Chain
1. **Routing Location**: Since `AdminController` already exists with `@RequestMapping("/api/admin")`, it is the most cohesive place to add the requested endpoints (`/users`, `/users/{id}`, `/users/{id}/password`, `/stats`).
2. **Separation of Concerns**: An `AdminService` should be created to encapsulate the business logic (fetching data, coordinating deletes, aggregating stats). The controller should delegate to this service.
3. **Data Privacy**: Because `User` lacks `@JsonIgnore` on the password, the GET `/users` endpoint must return a custom `UserDTO` (mapping id, email, fullName, bio, avatarUrl, status, lastLoginAt, createdAt, role).
4. **Data Integrity (Cascading Deletes)**: Deleting a `User` via `userRepository.delete(user)` will trigger foreign key constraints due to linked records. The `AdminService.deleteUser(Long id)` method must be `@Transactional` and manually invoke:
   - `refreshTokenRepository.deleteByUser(user)`
   - `templateRepository.deleteAll(templateRepository.findByUser(user))`
   - `birthdayRepository.deleteAll(birthdayRepository.findByUser(user))` (Requires adding `List<Birthday> findByUser(User user)` to `BirthdayRepository`).
   - Finally, `userRepository.delete(user)`.
5. **Password Update**: The PUT/PATCH `/api/admin/users/{id}/password` needs an ingestion DTO (e.g. `AdminPasswordUpdateRequest`) containing a `newPassword` string, which the `AdminService` encodes via the existing `PasswordEncoder` bean before saving the user.
6. **Stats Aggregation**: The GET `/api/admin/stats` endpoint can simply fetch aggregate counts (e.g., `userRepository.count()`, `birthdayRepository.count()`, `templateRepository.count()`) and return them as a `Map<String, Long>` or a dedicated `StatsDTO`.

## 3. Caveats
- No caveats regarding security routing, as Milestone 1 already completed the `WebSecurityConfig` adjustments.
- We assume deleting a user should forcefully hard-delete all their associated data (Birthdays, Templates, RefreshTokens). If a soft-delete strategy is preferred, the `deleteUser` method should merely set a flag, but based on the scope, hard deletion is standard for admin tools unless specified otherwise.
- The prompt asks for stats but does not specify exactly which metrics. Using total users, birthdays, and templates is a safe default.

## 4. Conclusion
The implementation should proceed by:
1. Creating `UserDTO` and `AdminPasswordUpdateRequest` in `app.time2wish.dto`.
2. Updating `app.time2wish.repository.BirthdayRepository` to add `List<Birthday> findByUser(User user)`.
3. Creating `app.time2wish.service.AdminService` to implement `getAllUsers`, `deleteUser(Long id)`, `updateUserPassword(Long id, String password)`, and `getStats()`.
4. Updating `app.time2wish.controller.AdminController` to define the 4 target endpoints using `AdminService`.

## 5. Verification Method
1. Build the application: `cd d:\formations_personnelles\time2wish-ai\backend && ./mvnw clean compile`
2. Run backend tests: `./mvnw test`
3. Functionality Verification: Spin up the Spring Boot app and execute authorized `GET /api/admin/users` to verify passwords are not returned. Execute an authorized `DELETE /api/admin/users/{id}` on a user that has Birthdays and Templates, verifying a 200 OK without a 500 Server Error (which would indicate an unresolved FK constraint).
