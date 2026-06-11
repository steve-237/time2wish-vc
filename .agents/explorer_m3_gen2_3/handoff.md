# Handoff Report: AdminControllerTest Compilation Fix Strategy

## 1. Observation
- The backend tests fail to compile due to `AdminControllerTest.java` (located at `backend/src/test/java/app/time2wish/controller/AdminControllerTest.java`).
- The file currently uses `@SpringBootTest` and `@AutoConfigureMockMvc` for class-level configuration.
- The file uses `@MockBean` from `org.springframework.boot.test.mock.mockito.MockBean` (line 12 and line 33), which no longer exists in this Spring Boot version.
- In comparison, `BirthdayControllerTest.java` successfully uses `@WebMvcTest(BirthdayController.class)` and `@MockitoBean` from `org.springframework.test.context.bean.override.mockito.MockitoBean`.
- `BirthdayControllerTest.java` also includes `@Import(WebSecurityConfig.class)` and declares `@MockitoBean` for `UserDetailsServiceImpl` and `JwtUtils` to satisfy the security dependencies of the web slice context.

## 2. Logic Chain
- To fix the missing `@MockBean` annotation, we must replace `import org.springframework.boot.test.mock.mockito.MockBean;` with `import org.springframework.test.context.bean.override.mockito.MockitoBean;` and change `@MockBean` to `@MockitoBean` on the `adminService` field.
- To fix the missing `@AutoConfigureMockMvc` (and heavy `@SpringBootTest` context), we must replace them with `@WebMvcTest(AdminController.class)` and `import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;`.
- Changing from `@SpringBootTest` (which loads the full application context) to `@WebMvcTest` (which only loads the web layer) means that security configurations will fail unless explicitly imported and their dependencies mocked. Therefore, we must add `@Import(WebSecurityConfig.class)` to `AdminControllerTest`.
- Since `WebSecurityConfig` requires `UserDetailsServiceImpl` and `JwtUtils`, we must mock these beans inside `AdminControllerTest` exactly as done in `BirthdayControllerTest.java` using `@MockitoBean`.

## 3. Caveats
- I did not run a full `mvn clean install` or equivalent command because I am operating in a read-only investigation mode.
- The recommendation assumes that `AdminController` has no other unmocked dependencies besides `AdminService` that would be exposed by transitioning to `@WebMvcTest`.

## 4. Conclusion
The fix requires replacing the outdated annotations and ensuring the sliced web test context has the required security beans. 

**Actionable Fix Strategy for `AdminControllerTest.java`**:
1. **Update Annotations**:
   - Remove `@SpringBootTest` and `@AutoConfigureMockMvc`.
   - Add `@WebMvcTest(AdminController.class)` and `@Import(WebSecurityConfig.class)`.
2. **Update Imports**:
   - Remove `org.springframework.boot.test.context.SpringBootTest`
   - Remove `org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc`
   - Remove `org.springframework.boot.test.mock.mockito.MockBean`
   - Add `org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest`
   - Add `org.springframework.context.annotation.Import`
   - Add `org.springframework.test.context.bean.override.mockito.MockitoBean`
   - Add `app.time2wish.security.WebSecurityConfig`
   - Add `app.time2wish.security.UserDetailsServiceImpl`
   - Add `app.time2wish.security.JwtUtils`
3. **Replace @MockBean**:
   - Change `@MockBean private AdminService adminService;` to `@MockitoBean private AdminService adminService;`
4. **Mock Security Dependencies**:
   - Add the following fields to the test class so the security config loads correctly:
     ```java
     @MockitoBean
     private UserDetailsServiceImpl userDetailsService;

     @MockitoBean
     private JwtUtils jwtUtils;
     ```

## 5. Verification Method
- Make the suggested changes to `backend/src/test/java/app/time2wish/controller/AdminControllerTest.java`.
- Run the backend tests using the project's build tool (e.g., `mvn test -Dtest=AdminControllerTest` or `./gradlew test --tests *AdminControllerTest`).
- Verify that the compilation error is resolved and the tests pass.
