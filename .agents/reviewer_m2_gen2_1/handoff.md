## Review Summary

**Verdict**: REQUEST_CHANGES

## Findings

### [Critical] Finding 1: Tests Fail to Compile
- **What**: The backend test suite does not compile, causing the build to fail.
- **Where**: `backend/src/test/java/app/time2wish/controller/AdminControllerTest.java`
- **Why**: The test file imports `org.springframework.boot.test.mock.mockito.MockBean` and `org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc`. `@MockBean` has been removed/moved in the Spring Boot version being targeted (likely Spring Boot 3.4+ where it's replaced by `@MockitoBean`). The test compilation fails with "package does not exist" and "cannot find symbol" errors.
- **Suggestion**: Update the imports and annotations. Use `@MockitoBean` instead of `@MockBean` if using Spring Boot 3.4+. Ensure the webmvc-test dependencies are correctly resolved.

### [Major] Finding 2: Admin Password Reset Fails to Invalidate Sessions
- **What**: Updating a user's password via the Admin API does not invalidate their existing sessions.
- **Where**: `backend/src/main/java/app/time2wish/service/AdminService.java` (`updateUserPassword` method)
- **Why**: When an admin forcibly changes a user's password, the user's active `RefreshToken`s should be deleted so that any malicious actor or previously logged-in session is forced to re-authenticate with the new password.
- **Suggestion**: Add a call to `refreshTokenRepository.deleteByUser(user);` inside `updateUserPassword()`.

### [Major] Finding 3: Lack of Input Validation on Password Updates
- **What**: The payload for the password update API is not validated.
- **Where**: `backend/src/main/java/app/time2wish/controller/AdminController.java` (`updateUserPassword` endpoint) and `AdminPasswordUpdateRequest.java`.
- **Why**: The DTO lacks validation annotations (e.g. `@NotBlank`, `@Size`), and the controller method lacks the `@Valid` annotation. An admin could unintentionally set an empty password or a password that violates the system's length policies.
- **Suggestion**: Add `@NotBlank` and `@Size(min = 6)` to `newPassword` in `AdminPasswordUpdateRequest`, and add `@Valid` to the `@RequestBody` parameter in the controller.

### [Minor] Finding 4: Statistics Include Soft-Deleted Records
- **What**: The `/api/admin/stats` endpoint reports total birthdays including soft-deleted ones.
- **Where**: `backend/src/main/java/app/time2wish/service/AdminService.java` (`getStats` method).
- **Why**: It uses `birthdayRepository.count()`, which counts all rows in the table. However, birthdays use a soft-delete mechanism (`is_deleted = true`). The statistic will misrepresent the number of active records.
- **Suggestion**: Create a repository method like `countByIsDeletedFalse()` and use it instead.

## Verified Claims
- **Claim**: Interface contracts are implemented correctly. → **Verified via view_file** → **PASS**. Endpoints, HTTP methods, and URL structures perfectly match the requirements in `PROJECT.md`.
- **Claim**: Deleting a user works correctly. → **Verified via view_file** → **PASS** (with caveats). It performs a cascading hard delete of associated refresh tokens, birthdays, and templates, which correctly cleans up the database and prevents foreign key constraint violations.

## Unverified Items
- The exact Spring Boot version. The `pom.xml` references `spring-boot-starter-parent` `4.0.6`, which seems to be a future/hypothetical version (in 2026), but the exact cause of the compilation failure matches the `@MockBean` deprecation path in 3.4+.

---

# Handoff Report

### 1. Observation
- Running `java -version` returns Java 8 by default locally, but the project requires Java 21 (as seen in `pom.xml` and `Dockerfile`).
- Setting `JAVA_HOME` to JDK 21 and running `./mvnw clean test` produces a compilation error in `AdminControllerTest.java`: `package org.springframework.boot.test.mock.mockito does not exist`.
- Inspecting `AdminPasswordUpdateRequest` and `AdminController` reveals no validation annotations.
- Inspecting `AdminService.updateUserPassword` reveals that it does not delete refresh tokens.
- Inspecting `AdminService.getStats` reveals it uses `birthdayRepository.count()`, while `BirthdayRepository.java` shows that `is_deleted` flags are used.

### 2. Logic Chain
- Milestone 2 requires the test suite to pass. Since `AdminControllerTest` fails to compile, this milestone cannot be considered complete.
- When an administrator resets a user's password, it is a standard security requirement to terminate active sessions to ensure the account is secured immediately. The lack of token invalidation is a security gap.
- An admin could easily send a blank string `{"newPassword": ""}` to the API, and the system would accept it, leaving the user with an empty password hash.
- Soft-deleted entities are usually considered non-existent from the business logic perspective, so counting them inflates the stats.

### 3. Caveats
- I did not test the endpoints at runtime since the application test compilation failed.
- The `pom.xml` indicates Spring Boot `4.0.6`. I assume this version drops `@MockBean` similarly to how `3.4.0` deprecated it in favor of `@MockitoBean`.

### 4. Conclusion
The implementation correctly structures the endpoints and performs the correct cascaded deletes for user removal. However, it fails on compilation of tests, lacks basic input validation for password updates, has a session invalidation security flaw on password resets, and miscalculates statistics. I am issuing a **REQUEST_CHANGES** verdict.

### 5. Verification Method
1. Run `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; ./mvnw clean test` to observe the `AdminControllerTest` compile errors.
2. View `AdminService.updateUserPassword` to see the missing `refreshTokenRepository.deleteByUser(user)` call.
3. View `AdminController.updateUserPassword` to see the missing `@Valid`.
