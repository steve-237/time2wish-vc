# Handoff Report: Milestone 2 Admin Issues Fix Strategy

## Observation

1. **`MockBean` deprecation issue**: `src/test/java/app/time2wish/controller/AdminControllerTest.java` currently uses `@MockBean` (imported from `org.springframework.boot.test.mock.mockito.MockBean`). In Spring Boot 3.4+, this annotation was replaced, causing a compilation failure.
2. **Missing 404 error handling**: In `src/main/java/app/time2wish/service/AdminService.java`, the methods `deleteUser(Long id)` and `updateUserPassword(Long id, String newPassword)` both perform a user lookup. If the user is not found, they throw a generic `RuntimeException("User not found")`. Because `AdminController.java` does not handle this exception, it bubbles up to Spring MVC, which responds with a `500 Internal Server Error` instead of the expected `404 Not Found`.
3. **Missing unit tests**: There is no `AdminServiceTest.java` in `src/test/java/app/time2wish/service/` to test the logic of `AdminService`.

## Logic Chain

1. **Fixing the Compilation Error**: To make `AdminControllerTest.java` compile with Spring Boot 3.4+, we need to replace the deprecated `@MockBean` annotation with `@MockitoBean`. The import must be changed from `org.springframework.boot.test.mock.mockito.MockBean` to `org.springframework.test.context.bean.override.mockito.MockitoBean`.
2. **Fixing 404 Error Handling**: The most Spring-native and direct way to return a 404 without adding new classes or `@ControllerAdvice` is to change `AdminService.java` to throw `org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "User not found")` instead of `RuntimeException`. Alternatively, a custom `UserNotFoundException` annotated with `@ResponseStatus(HttpStatus.NOT_FOUND)` can be created.
3. **Addressing Missing Tests**: A new `AdminServiceTest.java` class must be created using JUnit 5 and Mockito. It should mock `UserRepository`, `BirthdayRepository`, `RefreshTokenRepository`, `TemplateRepository`, and `PasswordEncoder`. It needs to cover success and "not found" scenarios for `deleteUser` and `updateUserPassword`, as well as `getAllUsers` and `getStats`.
4. **Validating 404 in Controller**: `AdminControllerTest.java` should also be updated with new test methods to verify that the `DELETE /api/admin/users/{id}` and `PUT /api/admin/users/{id}/password` endpoints properly return `404 Not Found` when the user does not exist.

## Caveats

- I assumed the use of `ResponseStatusException` for the 404 handling. If the project already has an established pattern for exception handling (e.g., a `@RestControllerAdvice`), a custom exception might be preferred, though my search did not reveal any general `ResourceNotFoundException`.
- The frontend was not investigated as the issues reported were strictly related to the backend controllers and routing.

## Conclusion

To resolve the failing Iteration 1 of Milestone 2:
1. Update `AdminControllerTest.java` to use `@MockitoBean`.
2. Modify `AdminService.java` to throw `ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")`.
3. Create `AdminServiceTest.java` with comprehensive unit tests for all `AdminService` methods.
4. Add 404 test cases to `AdminControllerTest.java`.

## Verification Method

- Run the backend test suite (e.g., `./mvnw clean test` or `mvn clean test` depending on the wrapper).
- The compilation of tests should succeed.
- All tests in `AdminControllerTest` and the new `AdminServiceTest` should pass.
- Inspect endpoints manually or via the test output to confirm `404 Not Found` is correctly returned for invalid user IDs.
