# Handoff: Frontend Admin Layout & Routing Strategy

## 1. Observation
- The frontend uses standalone Angular components with routing defined in `frontend/src/app/app.routes.ts`.
- The root layout is currently hardcoded into `frontend/src/app/app.html`, wrapping everything inside a standard `<header>` and `<footer>` when a user is authenticated (`@if (authService.isAuthenticated())`).
- The backend `AuthController` (`/api/auth/login`, `/refresh`, `/profile`) returns a `JwtResponse` that explicitly omits the user's role.
- The frontend `AuthService` and `User` interface (in `birthday.model.ts`) do not track the user's role.
- The `auth.guard.ts` only checks if `authService.isAuthenticated()` and redirects to `/login` otherwise.

## 2. Logic Chain
1. To create a "distinct separate layout for the Admin interface" (M3 objective) without the standard user `<header>` and `<footer>` bleeding into the admin pages, the layout must be decoupled from the root `app.html`.
2. Extracting the user layout into a `MainLayoutComponent` and creating a new `AdminLayoutComponent` allows `app.routes.ts` to cleanly separate the two environments.
3. To protect the admin routes using a new Route Guard (`admin.guard.ts`), the frontend must know if the authenticated user is an admin.
4. Because the JWT token payload (claims) and `JwtResponse` do not contain role information, the frontend currently has no way to distinguish a standard user from an admin. The backend must be updated to include the `role` in the `JwtResponse`.

## 3. Caveats
- Modifying the backend `JwtResponse` implies restarting the backend.
- The logic inside `app.ts` that handles language switching, dark mode, and PWA logic relies heavily on the header. When moving the header to `MainLayoutComponent`, some of these signals and methods might need to be shifted to the layout component, or exposed via an injected service.

## 4. Conclusion
The implementation of the Frontend Admin Layout requires a 5-step strategy:

**1. Backend Adjustments**
- Add `private String role;` to `backend/src/main/java/app/time2wish/dto/JwtResponse.java`.
- Update `AuthController.java` (in `login`, `refresh`, `profile`) to map the role: `.role(user.getRole().name())` when returning `JwtResponse`.

**2. Frontend Models**
- Add `role?: string;` to the `User` interface in `frontend/src/app/models/birthday.model.ts`.
- Update the `AuthResponse` interface in `frontend/src/app/services/auth.service.ts` to include `role: string;`, and map it when saving the session.

**3. Implement `AdminGuard`**
- Create `frontend/src/app/guards/admin.guard.ts` checking `authService.currentUser()?.role === 'ROLE_ADMIN'`. Redirect unauthorized users to `/dashboard`.

**4. Create Layout Components**
- **`MainLayoutComponent`**: Move `<header>` and `<footer>` from `app.html` to here.
- **`AdminLayoutComponent`**: Create a new wrapper for the admin panel with its own `<router-outlet>`.
- **`app.html`**: Simplify to just `<router-outlet>` and `<app-toast-container>`.

**5. Route Configuration (`app.routes.ts`)**
- Group existing user routes under a `component: MainLayoutComponent` route.
- Add an `admin` route with `component: AdminLayoutComponent` and `canActivate: [adminGuard]`.
- Use lazy loading for admin pages: `loadChildren: () => import('./pages/admin/admin.routes').then(m => m.routes)`.

## 5. Verification Method
- Build the backend: `cd backend && mvn clean install`
- Start the frontend: `cd frontend && npm start`
- Try to access `/admin` as a normal user. The `AdminGuard` should block access.
- Accessing `/admin` as an admin should display the `AdminLayoutComponent` without the standard user header/footer.
