# Handoff Report: Milestone 1 (Backend Admin Roles)

## Observation
- **Roles Definition**: Examined `app.time2wish.model.User` and `app.time2wish.security.UserDetailsImpl`. Roles are currently hardcoded in `UserDetailsImpl.build()`: `Collections.singletonList(new SimpleGrantedAuthority("ROLE_USER"))`. There is no role representation in the `User` entity, and the database schema in `src/main/resources/db/migration/V1__init_schema.sql` lacks a role-related column.
- **SecurityFilterChain**: Examined `app.time2wish.security.WebSecurityConfig`. The `SecurityFilterChain` defines `permitAll()` for `/api/auth/**` and `/api/files/**`, and `.anyRequest().authenticated()`. There are no role-based authorization rules configured.
- **Admin Endpoints**: Searched for `/api/admin` and `admin` keywords in the backend Java sources. Found 0 results. There are no existing admin endpoints.

## Logic Chain
- Because roles are hardcoded to `ROLE_USER` in `UserDetailsImpl`, the application currently treats all users as having identical privileges. A persistent role model needs to be introduced in the database (via Flyway migration) and the `User` entity.
- Because `WebSecurityConfig` currently only enforces authentication for non-public paths, we must add a specific path matcher for `/api/admin/**` that enforces the `ROLE_ADMIN` requirement before the catch-all `.anyRequest().authenticated()`.
- Since there are no existing `/api/admin` endpoints, we must create a new controller (e.g., `AdminController`) to serve as the entry point for admin functionalities.

## Caveats
- The proposed solution below uses a single `Role` enum field mapped as a string column. If future business requirements dictate that a user can possess multiple roles simultaneously, a `@ManyToMany` relationship with separate `roles` and `user_roles` tables will be required instead.
- Assuming Flyway is used for database migrations based on the `src/main/resources/db/migration` directory contents. The latest migration found was `V6`, so the new script should be `V7`.

## Conclusion
Implementation Plan for Milestone 1:

1. **Database Migration**: Create `src/main/resources/db/migration/V7__add_role_to_users.sql`:
   ```sql
   ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER';
   ```
2. **Entity Update**: Create a `Role` enum (`ROLE_USER`, `ROLE_ADMIN`) and update `app.time2wish.model.User`:
   ```java
   @Enumerated(EnumType.STRING)
   @Column(nullable = false, length = 20)
   private Role role = Role.ROLE_USER;
   ```
3. **UserDetails Update**: Update `app.time2wish.security.UserDetailsImpl.build()` to extract the role dynamically:
   ```java
   List<GrantedAuthority> authorities = Collections.singletonList(
       new SimpleGrantedAuthority(user.getRole() != null ? user.getRole().name() : "ROLE_USER")
   );
   ```
4. **Security Configuration**: Update `app.time2wish.security.WebSecurityConfig`:
   ```java
   .authorizeHttpRequests(auth -> 
       auth.requestMatchers("/api/auth/**").permitAll()
           .requestMatchers("/api/files/**").permitAll()
           .requestMatchers("/api/admin/**").hasRole("ADMIN")
           .anyRequest().authenticated()
   );
   ```
5. **Admin Controller**: Create `app.time2wish.controller.AdminController` annotated with `@RestController` and `@RequestMapping("/api/admin")` to house future admin APIs.

## Verification Method
- **Test Command**: `mvn clean test`
- **Manual Verification**: Launch the backend (`mvn spring-boot:run`).
- **Validation**:
  - Issue a GET request to a new `/api/admin/test` endpoint with a JWT belonging to a user with `ROLE_USER`. The expected response is `403 Forbidden`.
  - Issue the same request with a JWT belonging to a user with `ROLE_ADMIN`. The expected response is `200 OK`.
  - Write integration tests using `@SpringBootTest` and `@WithMockUser(roles = "ADMIN")` to assert the authorization rules.
