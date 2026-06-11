# Handoff Report: Milestone 2 Fix Strategy

## Observation
1. **Test Compilation**: In `backend/src/test/java/app/time2wish/controller/AdminControllerTest.java` lines 12 and 33, `org.springframework.boot.test.mock.mockito.MockBean` and `@MockBean` are used, which are deprecated/removed in newer Spring Boot versions.
2. **Missing Token Invalidation**: In `backend/src/main/java/app/time2wish/service/AdminService.java` (line 76), `updateUserPassword()` changes the password but fails to delete tokens using `refreshTokenRepository`.
3. **Lack of Input Validation**: `backend/src/main/java/app/time2wish/dto/AdminPasswordUpdateRequest.java` lacks annotations on `newPassword`. In `backend/src/main/java/app/time2wish/controller/AdminController.java` (line 41), `updateUserPassword()` lacks the `@Valid` annotation on its `@RequestBody`. `AdminControllerStressTest.java` expects 400 Bad Request for an empty password.
4. **Statistics Soft-Deleted Records**: In `AdminService.java` (line 85), `getStats()` calculates `totalBirthdays` using `birthdayRepository.count()`. `BirthdayRepository.java` lacks a `countByIsDeletedFalse()` method.
5. **Generic Error Handling**: In `AdminService.java` (lines 58 and 78), a missing user throws a generic `RuntimeException("User not found")`, resulting in a 500 error instead of a 404 Not Found.
6. **Missing Service Tests**: There is no `AdminServiceTest.java` file in `backend/src/test/java/app/time2wish/service/`.

## Logic Chain
1. **Test Compilation**: Replacing `org.springframework.boot.test.mock.mockito.MockBean` with `org.springframework.test.context.bean.override.mockito.MockitoBean` and using `@MockitoBean` in `AdminControllerTest.java` will fix the compilation error caused by the Spring Boot upgrade.
2. **Missing Token Invalidation**: Adding `refreshTokenRepository.deleteByUser(user);` to `AdminService.updateUserPassword()` ensures sessions are invalidated, forcing users to re-authenticate after a password change.
3. **Lack of Input Validation**: Adding `@NotBlank` and `@Size(min = 6)` to `AdminPasswordUpdateRequest.newPassword` along with `@Valid` in `AdminController.updateUserPassword()` will enable standard validation, throwing 400 Bad Request for invalid inputs.
4. **Statistics**: Defining `long countByIsDeletedFalse();` in `BirthdayRepository` and replacing `birthdayRepository.count()` with `birthdayRepository.countByIsDeletedFalse()` in `AdminService.getStats()` will correctly exclude soft-deleted birthdays.
5. **Generic Error Handling**: Replacing `new RuntimeException("User not found")` with `new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")` ensures proper 404 status codes, passing the corresponding test in `AdminControllerStressTest`.
6. **Missing Service Tests**: Creating `AdminServiceTest.java` using `@ExtendWith(MockitoExtension.class)` with `@Mock` and `@InjectMocks` will provide the missing unit tests for `AdminService`.

## Caveats
- I am operating in a read-only explorer capacity and did not implement or test these changes directly.
- The `pom.xml` indicates a spring-boot-starter-parent version of `4.0.6` (which implies Spring Boot 3.4+ behavior like the `@MockitoBean` change).

## Conclusion
The implementer agent must apply these 6 targeted fixes across `AdminControllerTest`, `AdminService`, `AdminController`, `AdminPasswordUpdateRequest`, and `BirthdayRepository`, and create the missing `AdminServiceTest` to resolve all failures.

## Verification Method
1. Make the 6 implementation changes described above.
2. Create the missing `AdminServiceTest.java`.
3. Set the correct Java version: `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"`
4. Run the test suite: `cd backend; ./mvnw clean test`
5. Ensure all tests (including the failing integration tests in `AdminControllerStressTest`) pass successfully.
