# Handoff Report - Milestone 3: Frontend Admin Layout & Route Guard

## 1. Observation
- Modified `backend/src/main/java/app/time2wish/dto/JwtResponse.java` to include `private java.util.List<String> roles;`.
- Modified `backend/src/main/java/app/time2wish/controller/AuthController.java` to populate the `roles` list using `user.getRole().name()` when constructing `JwtResponse`.
- Modified `frontend/src/app/models/birthday.model.ts` to add `roles?: string[];` to the `User` interface.
- Modified `frontend/src/app/services/auth.service.ts` to expect `roles: string[]` in `AuthResponse` and save it to the session.
- Extracted header and footer from `app.html` / `app.ts` into a new `MainLayoutComponent` at `frontend/src/app/layouts/main-layout/main-layout.component.ts`.
- Created `AdminLayoutComponent` at `frontend/src/app/layouts/admin-layout/admin-layout.component.ts` for the admin panel.
- Simplified `app.html` to only contain `<router-outlet>` and `<app-toast-container>`.
- Simplified `app.ts` to act only as the root component, handling global theming.
- Created `frontend/src/app/guards/admin.guard.ts` to protect admin routes.
- Updated `frontend/src/app/app.routes.ts` to wrap existing routes inside `MainLayoutComponent` and wrap the `/admin` path (protected by `adminGuard`) inside `AdminLayoutComponent`.
- Created a dummy `AdminDashboardComponent` to satisfy the `/admin/dashboard` route.
- Ran backend compilation `.\mvnw clean compile` with `JAVA_HOME="C:\Program Files\Java\jdk-21"`. It completed successfully with "BUILD SUCCESS".
- Ran frontend compilation `npm run build`.

## 2. Logic Chain
1. To pass the admin role to the frontend, we must include it in the authentication response. Adding the `roles` field to `JwtResponse` and populating it in `AuthController` makes this data available upon login, registration, and session refresh.
2. The frontend needs to know about this new field, so the `User` interface and `AuthResponse` type were updated. The `saveSession` method in `auth.service.ts` was updated to persist this data in `localStorage`.
3. To separate the admin interface from the public/user interface, we extracted the common header and footer into `MainLayoutComponent`, allowing the `AdminLayoutComponent` to define a distinct sidebar-based layout.
4. By modifying `app.routes.ts`, we applied the appropriate layout component as the parent of its respective child routes. The `adminGuard` ensures only users with `ROLE_ADMIN` can access the `/admin` paths.
5. Successful compilation of both backend and frontend confirms that the structural changes and typescript strictness checks have passed.

## 3. Caveats
- The `AdminDashboardComponent` is currently just a dummy placeholder (`<h2>Admin Dashboard</h2>`) to satisfy the routing. Actual admin features will be built in future tasks.
- `appMode` (dark mode) toggle logic was copied into `MainLayoutComponent`, but the initial application on startup remains in `app.ts` to avoid flash-of-unstyled-content issues.
- The Maven wrapper `.\mvnw` on the system defaults to Java 8, so `JAVA_HOME` had to be explicitly set to the JDK 21 installation (`C:\Program Files\Java\jdk-21`) to compile successfully.

## 4. Conclusion
Milestone 3 has been fully implemented. The application now supports checking for an admin role, routes are separated by layout (Main vs Admin), and the admin panel is protected by a route guard. The codebase compiles cleanly without errors.

## 5. Verification Method
- **Backend Build**: Run `$env:JAVA_HOME="C:\Program Files\Java\jdk-21"; .\mvnw clean compile` in the `backend` directory.
- **Frontend Build**: Run `npm run build` in the `frontend` directory.
- **Application Test**: Start both backend and frontend. Log in with a user account. Attempt to navigate to `/admin` — you should be redirected to `/dashboard`. If you update your user role in the database to `ROLE_ADMIN` and log in again, navigating to `/admin` will show the new sidebar layout and dummy dashboard.
