# Iteration 1 Failure Report

The previous iteration failed the Reviewer gate. The Reviewers identified the following critical and major issues that need to be addressed:

1. **Test Compilation Failure / Java Version**: The backend tests fail to compile. This is partially because of `@MockBean` being used instead of `@MockitoBean` (likely Spring Boot 3.4+). Additionally, Maven needs to be run with Java 21. Use `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; ./mvnw clean test` to ensure JDK 21 is used.
2. **Missing Token Invalidation on Password Reset**: When an admin changes a user's password (`updateUserPassword`), the user's active `RefreshToken`s must be deleted to force re-authentication.
3. **Lack of Input Validation**: `AdminPasswordUpdateRequest` lacks `@NotBlank` and `@Size(min = 6)`. The `updateUserPassword` controller method lacks `@Valid`.
4. **Statistics Include Soft-Deleted Records**: The `/api/admin/stats` endpoint counts all birthdays, but birthdays use a soft-delete mechanism. A custom repository method like `countByIsDeletedFalse()` should be used.
5. **Generic Error Handling**: `AdminService.deleteUser` and `updateUserPassword` throw generic `RuntimeException` when a user is not found, leading to 500 errors. This should be changed to a 404 Not Found exception (e.g., `ResponseStatusException(HttpStatus.NOT_FOUND)`).
6. **Missing Service Tests**: There are no unit tests for `AdminService`. An `AdminServiceTest.java` must be created to verify the business logic.

Explore the codebase and provide a fix strategy for these issues.
