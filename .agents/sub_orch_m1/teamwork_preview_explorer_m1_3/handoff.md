# Handoff Report: Backend Admin Roles

## Observation
- **Roles in Security**: In `app/time2wish/security/UserDetailsImpl.java` (lines 30-37), the role is currently hardcoded for all authenticated users: `Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))`.
- **User Entity**: The `app.time2wish.model.User` entity does not have a `role` field.
- **Database Schema**: `src/main/resources/application.yml` specifies `spring.flyway.enabled: true` and `spring.jpa.hibernate.ddl-auto: validate`. There are currently 6 Flyway migrations in `src/main/resources/db/migration/`.
- **SecurityFilterChain**: In `app/time2wish/security/WebSecurityConfig.java` (lines 65-69), the filter chain permits `/api/auth/**` and `/api/files/**`, and requires authentication for all other requests. There are no path matchers restricting access to `/api/admin/**`.
- **Admin Endpoints**: A `grep_search` for `/api/admin` across all Java files returned 0 results. There are currently no existing endpoints under `/api/admin`.

## Logic Chain
1. To support `ROLE_ADMIN` and `ROLE_USER`, the database `users` table needs a new column to store the user's role. Since `ddl-auto` is set to `validate`, this must be done via a new Flyway migration.
2. The `User` entity must be updated to map this new database column. We can use an Enum `Role` to represent `ROLE_USER` and `ROLE_ADMIN`.
3. `UserDetailsImpl` must be modified to read the role from the `User` entity instead of hardcoding `ROLE_USER`.
4. `WebSecurityConfig` needs to be updated to secure the `/api/admin/**` wildcard. Specifically, adding `.requestMatchers("/api/admin/**").hasRole("ADMIN")` before `.anyRequest().authenticated()`.

## Caveats
- There are no existing admin controllers to test the `/api/admin/**` security. The implementer might want to create a simple `AdminController` with a test endpoint (e.g., `GET /api/admin/test`) to verify the implementation.
- Since Lombok's `@Builder` is used in `User`, fields initialized at declaration (like `role = Role.ROLE_USER`) will be ignored by the builder unless explicitly set during the build or marked with `@Builder.Default`. The implementer needs to be careful when constructing new users in `AuthController.registerUser`.

## Conclusion
To complete Milestone 1, the implementer needs to:
1. **Create an Enum**: `app.time2wish.model.Role` with `ROLE_USER` and `ROLE_ADMIN`.
2. **Update `User.java`**: Add a `role` field mapped as `@Enumerated(EnumType.STRING)` and configure it properly with Lombok's builder.
3. **Add Flyway Migration**: Create `V7__add_roles_to_user.sql` to add `role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER'` to the `users` table.
4. **Update `UserDetailsImpl.java`**: Map the role dynamically from the `User` object.
5. **Update `WebSecurityConfig.java`**: Add `.requestMatchers("/api/admin/**").hasRole("ADMIN")`.
6. **Update `AuthController.java`**: Ensure newly registered users get assigned `ROLE_USER` by default.

## Verification Method
- **Compilation**: Run `./mvnw clean compile` to ensure the project builds with the new enum and configuration.
- **Migration test**: Start the application (or run tests) to verify Flyway successfully applies `V7__add_roles_to_user.sql`.
- **Security test**: A new user should have `ROLE_USER` and receive HTTP 403 Forbidden when attempting to access a mocked `/api/admin/test` endpoint. An admin user (manually updated in the DB) should receive HTTP 200 OK.
