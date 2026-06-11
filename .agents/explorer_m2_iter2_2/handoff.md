# Handoff Report: Milestone 2 Backend Admin APIs Fix Strategy

## 1. Observation
- **Test Compilation Failure**: `AdminControllerTest.java` (line 12, 33) uses `@MockBean`. In Spring Boot 3.4+ (pom.xml indicates 4.0.6), this is deprecated/removed and replaced by `@MockitoBean`. 
- **Missing Token Invalidation**: `AdminService.java` lines 76-81 updates the user password but does not invalidate refresh tokens.
- **Lack of Input Validation**: `AdminPasswordUpdateRequest.java` lacks `jakarta.validation.constraints.*` annotations on the `newPassword` field. `AdminController.java` (line 41) lacks `@Valid` on the `@RequestBody`.
- **Statistics Soft-Deleted Records**: `AdminService.java` (line 85) uses `birthdayRepository.count()` which includes soft-deleted records. `BirthdayRepository.java` lacks a `countByIsDeletedFalse()` method.
- **Generic Error Handling**: `AdminService.deleteUser` (line 58) and `updateUserPassword` (line 78) throw `RuntimeException("User not found")`, which causes 500 errors instead of 404s.
- **Missing Service Tests**: No `AdminServiceTest.java` exists under `backend/src/test/java/app/time2wish/service/`.

## 2. Logic Chain
- To fix test compilation, `@MockBean` must be replaced with `@MockitoBean` (import: `org.springframework.test.context.bean.override.mockito.MockitoBean`).
- To enforce re-authentication upon a password reset, `refreshTokenRepository.deleteByUser(user)` must be called within `AdminService.updateUserPassword`.
- To validate input properly, `@NotBlank` and `@Size(min = 6)` are required on `AdminPasswordUpdateRequest.newPassword`, and `@Valid` is required in the Controller to trigger the validation.
- To provide accurate statistics, the `BirthdayRepository` needs `long countByIsDeletedFalse();` to exclude soft-deleted items, and `AdminService` should use it instead of `count()`.
- To handle 'Not Found' errors gracefully and return a 404 HTTP status, the generic `RuntimeException` should be replaced with `ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")`.
- `AdminServiceTest.java` must be created to cover unit tests for business logic, ensuring robustness and satisfying the missing coverage.

## 3. Caveats
- JDK 21 is required to compile and test the application, which should be handled by setting `$env:JAVA_HOME` appropriately before running maven commands.
- For testing `AdminService.java` in `AdminServiceTest.java`, an `@ExtendWith(MockitoExtension.class)` test setup mocking `UserRepository`, `BirthdayRepository`, etc., will be required to properly test all branches (including the new 404 exception paths).

## 4. Conclusion
The fix strategy is clear and well-defined:
1. **Tests Compilation**: Replace `org.springframework.boot.test.mock.mockito.MockBean` with `org.springframework.test.context.bean.override.mockito.MockitoBean` in `AdminControllerTest.java` and `AdminControllerStressTest.java`.
2. **Token Invalidation**: Add `refreshTokenRepository.deleteByUser(user);` to `AdminService.updateUserPassword()`.
3. **Validation**: Add `@NotBlank` and `@Size(min = 6)` to `AdminPasswordUpdateRequest.newPassword` and `@Valid` to `AdminController.updateUserPassword()` parameter.
4. **Stats Fix**: Add `long countByIsDeletedFalse();` to `BirthdayRepository` and use it in `AdminService.getStats()`.
5. **Error Handling**: Replace `new RuntimeException(...)` with `new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")` in `AdminService`.
6. **Service Tests**: Create `AdminServiceTest.java` with unit tests for `getAllUsers`, `deleteUser`, `updateUserPassword`, and `getStats`.

## 5. Verification Method
- **Compilation & Test**: Run `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; ./mvnw clean test` to ensure tests pass and compile successfully.
- **Code Inspection**: Review `AdminService.java`, `AdminController.java`, `AdminPasswordUpdateRequest.java`, and `BirthdayRepository.java` to confirm all changes from the conclusion are implemented.
