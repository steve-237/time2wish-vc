# Handoff Report: Backend Admin Roles Strategy

## Observation
- **Scope & Goal**: According to `SCOPE.md`, the objective is to implement `ROLE_USER` and `ROLE_ADMIN` and secure `/api/admin/*`.
- **Current Spring Security Config**: `src/main/java/app/time2wish/security/WebSecurityConfig.java` configures `SecurityFilterChain` with permit-all for `/api/auth/**` and `/api/files/**`, and `.anyRequest().authenticated()`. There are no rules for `/api/admin`.
- **User Entity & Roles**: `src/main/java/app/time2wish/model/User.java` defines the `User` entity but has no `role` or `authorities` fields.
- **UserDetails**: `src/main/java/app/time2wish/security/UserDetailsImpl.java` dynamically builds the user context but hardcodes the role: `Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))`.
- **Database Schema**: The project uses Flyway migrations (`src/main/resources/db/migration/`). The `users` table (created in `V1__init_schema.sql`) does not have a role column. The latest migration is `V6`.
- **Controllers**: There are no existing endpoints mapped to `/api/admin` in `src/main/java/app/time2wish/controller/`.

## Logic Chain
1. **Schema Update**: Because Flyway is enabled and Hibernate is set to `validate`, a new migration script (`V7__add_user_roles.sql`) is required to add a `role` column to the `users` table. Assigning a default value of `'ROLE_USER'` will gracefully migrate existing records.
2. **Entity Update**: To read/write this column via JPA, an `ERole` enum (with values `ROLE_USER`, `ROLE_ADMIN`) must be created, and a `role` property added to `User.java` with `@Enumerated(EnumType.STRING)`. This implies a single role per user, which is standard and sufficient for MVP.
3. **Security Context**: `UserDetailsImpl.java` must be modified so that `build(User user)` utilizes `user.getRole().name()` to assign the granted authority, rather than hardcoding `"ROLE_USER"`.
4. **Endpoint Protection**: The `SecurityFilterChain` in `WebSecurityConfig.java` needs a new route matcher: `.requestMatchers("/api/admin/**").hasRole("ADMIN")` or `.hasAuthority("ROLE_ADMIN")` positioned *before* `.anyRequest().authenticated()`.
5. **Controller Implementation**: To fulfill the milestone, an `AdminController` should be created to provide at least one `/api/admin` endpoint (e.g., a GET method for user management).

## Caveats
- Assuming a single role per user is adequate for the current requirements (a `VARCHAR` column vs a Many-to-Many `user_roles` table). This simplifies the schema and queries.
- We rely on standard Spring Security `hasRole("ADMIN")` which expects the authority string to be `"ROLE_ADMIN"`.
- If the application starts rejecting requests immediately due to the role column missing, it's because Flyway needs to execute. The backend must be restarted successfully to apply `V7`.

## Conclusion
The implementation strategy is straightforward:
1. **Add Flyway script `V7__add_user_roles.sql`**: `ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER';`
2. **Create `ERole.java` enum** in `app.time2wish.model` containing `ROLE_USER` and `ROLE_ADMIN`.
3. **Update `User.java`**: Add `@Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private ERole role = ERole.ROLE_USER;`
4. **Update `UserDetailsImpl.java`**: Change the hardcoded authority to `new SimpleGrantedAuthority(user.getRole().name())`.
5. **Update `WebSecurityConfig.java`**: Add `.requestMatchers("/api/admin/**").hasRole("ADMIN")` in the `authorizeHttpRequests` chain.
6. **Create `AdminController.java`** in `app.time2wish.controller` mapped to `@RequestMapping("/api/admin")` with basic skeleton endpoints.

## Verification Method
1. **Build & Test**: Run the project tests via `./mvnw clean test` (or the equivalent Maven command) to ensure compilation succeeds and existing Auth/Birthday tests pass.
2. **Schema verification**: Start the application and check the logs to verify Flyway successfully applied `V7`.
3. **Endpoint Validation**: 
   - Start the backend.
   - Send an unauthenticated GET request to `/api/admin/...` -> Expect **401 Unauthorized**.
   - Login as a normal user, send request with Bearer token -> Expect **403 Forbidden**.
   - Manually update the user's role to `ROLE_ADMIN` in the DB, get a new token, and request again -> Expect **200 OK**.
