# Implementation Plan: Backend Admin Roles

## Synthesized Consensus from Explorers

1. **Database Schema Update (Flyway)**
   - Create a new migration script `V7__add_user_roles.sql` in `src/main/resources/db/migration/`.
   - Content: `ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'ROLE_USER';`

2. **Enum Creation**
   - Create an enum `app.time2wish.model.Role` (or `ERole`) with values `ROLE_USER` and `ROLE_ADMIN`.

3. **User Entity Update**
   - Update `app.time2wish.model.User.java`.
   - Add a `role` field:
     ```java
     @Enumerated(EnumType.STRING)
     @Column(nullable = false, length = 20)
     private Role role = Role.ROLE_USER;
     ```
   - Ensure Lombok `@Builder.Default` is used if `@Builder` is present on the class.

4. **Security Context Update**
   - Update `app.time2wish.security.UserDetailsImpl.java`.
   - Instead of hardcoding `new SimpleGrantedAuthority("ROLE_USER")`, use the user's role: `new SimpleGrantedAuthority(user.getRole().name())`.

5. **Security Filter Chain Update**
   - Update `app.time2wish.security.WebSecurityConfig.java`.
   - Add `.requestMatchers("/api/admin/**").hasRole("ADMIN")` (or `.hasAuthority("ROLE_ADMIN")`) before the `.anyRequest().authenticated()` rule.

6. **Auth Controller Update**
   - Review `app.time2wish.controller.AuthController.java` (if necessary) to ensure new users are explicitly saved with `ROLE_USER` upon registration.

7. **Admin Controller Creation**
   - Create a basic `app.time2wish.controller.AdminController.java`.
   - Map it to `@RestController` and `@RequestMapping("/api/admin")`.
   - Add a dummy test endpoint (e.g., `GET /api/admin/test` returning a simple message) to allow verification of the security rules.

## Verification
- `mvn clean compile test` to ensure code compiles and tests pass.
- Application must start successfully so Flyway runs `V7`.
