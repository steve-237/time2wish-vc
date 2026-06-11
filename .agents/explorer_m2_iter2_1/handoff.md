# Handoff: Backend Admin APIs Fix Strategy (Milestone 2, Iteration 2)

## 1. Observation
- **Test Compilation Failure**: `src/test/java/app/time2wish/controller/AdminControllerTest.java` and `AdminControllerStressTest.java` use `@MockBean` from `org.springframework.boot.test.mock.mockito.MockBean` which causes compilation errors in Spring Boot 3.4+.
- **Missing Token Invalidation**: `src/main/java/app/time2wish/service/AdminService.java` (lines 75-81) updates the user's password but does not call `refreshTokenRepository.deleteByUser(user)` to invalidate active sessions.
- **Lack of Input Validation**: `src/main/java/app/time2wish/dto/AdminPasswordUpdateRequest.java` contains `private String newPassword;` without `@NotBlank` or `@Size`. `src/main/java/app/time2wish/controller/AdminController.java`'s `updateUserPassword` method lacks the `@Valid` annotation on the request payload.
- **Statistics Include Soft-Deleted Records**: `src/main/java/app/time2wish/repository/BirthdayRepository.java` lacks a method to filter out soft-deleted records. `AdminService.getStats` (lines 83-87) uses `birthdayRepository.count()` which includes all records, ignoring the `isDeleted` flag from `Birthday.java`.
- **Generic Error Handling**: `AdminService.deleteUser` (line 58) and `updateUserPassword` (line 78) throw `new RuntimeException("User not found")`.
- **Missing Service Tests**: There is no unit test file for `AdminService`.

## 2. Logic Chain
1. **Test Compilation**: Replacing `@MockBean` with `@MockitoBean` from `org.springframework.test.context.bean.override.mockito.MockitoBean` in the test classes will resolve the test compilation failures caused by the Spring Boot version update.
2. **Token Invalidation**: Calling `refreshTokenRepository.deleteByUser(user)` immediately before saving the new password in `updateUserPassword` ensures that active user sessions are forcibly revoked upon a password reset.
3. **Input Validation**: Adding `@NotBlank` and `@Size(min = 6)` to the DTO's `newPassword` field and prepending `@Valid` to the `@RequestBody` in the controller enforces payload validation, resolving the missing constraints.
4. **Statistics**: Implementing `long countByIsDeletedFalse();` in `BirthdayRepository` and invoking it in `AdminService.getStats()` ensures the stats endpoint strictly counts active birthdays.
5. **Error Handling**: Replacing `RuntimeException` with `ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")` properly propagates a 404 HTTP status when a requested user ID doesn't exist, avoiding generic 500 errors.
6. **Service Tests**: Creating `AdminServiceTest.java` using JUnit 5 and Mockito is necessary to ensure adequate code coverage for the `AdminService` business logic.

## 3. Caveats
- The `mvn test` output also reported `package org.springframework.boot.test.autoconfigure.web.servlet does not exist` for `AutoConfigureMockMvc`. This might be a cascading failure caused by the `@MockBean` import, or it might require an alternative import if the Spring Boot version has changed `AutoConfigureMockMvc`'s package location. The implementer should verify test compilation after updating `@MockitoBean`.
- Validation annotations require the `spring-boot-starter-validation` dependency, which is confirmed to be present in `pom.xml`.

## 4. Conclusion
The implementation is ready to be fixed. An implementer agent should:
1. Update `AdminControllerTest.java` and `AdminControllerStressTest.java` to use `@MockitoBean`.
2. Enhance `AdminService` to invalidate tokens on password change and throw `ResponseStatusException(HttpStatus.NOT_FOUND)` on missing users.
3. Add Jakarta validation annotations (`@NotBlank`, `@Size`, `@Valid`) to `AdminPasswordUpdateRequest` and `AdminController`.
4. Add `countByIsDeletedFalse()` to `BirthdayRepository` and use it in `AdminService.getStats()`.
5. Create `AdminServiceTest.java` with tests for all service methods.

## 5. Verification Method
1. After implementation, run: `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; ./mvnw clean test`
2. Ensure all tests (including the new `AdminServiceTest`) compile successfully and pass.
3. Verify that `mvnw` builds without compilation errors and that no checkstyle/linter errors are introduced.
