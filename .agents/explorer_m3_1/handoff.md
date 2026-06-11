# Handoff: Milestone 3 - Frontend Admin Layout

## Core Findings Summary
The Angular frontend currently uses a monolithic root layout (`app.ts` / `app.html`) that applies globally. To support a separate Admin Layout, the routing architecture needs to be refactored to use layout wrapper components. Additionally, the frontend user models (`AuthResponse` and `User`) currently lack a role property to distinguish admin users, which is required for the new `adminGuard`.

## 1. Observation
- **`src/app/app.ts` & `src/app/app.html`**: The root component contains all the header, language selection, theme toggling, and footer logic, wrapping a single `<router-outlet>`. This hardcodes the layout for all routes.
- **`src/app/app.routes.ts`**: Routes are defined in a flat list (except for `dashboard` children). There is no layout grouping.
- **`src/app/services/auth.service.ts`**: `AuthResponse` interface (lines 7-14) only contains `token`, `id`, `email`, `fullName`, `bio`, `avatarUrl`. It does not parse or store user roles.
- **`src/app/models/birthday.model.ts`**: The `User` interface (lines 1-8) defines `status` but no `role` or `roles` property.
- **`src/app/guards/auth.guard.ts`**: Only checks `authService.isAuthenticated()`. There is no role-based guard present.

## 2. Logic Chain
- Because the layout is hardcoded in `app-root`, navigating to an admin route would currently render the standard user header and footer. To fix this, the UI shell must be extracted into a dedicated `MainLayoutComponent`, allowing `app-root` to dynamically render either `MainLayoutComponent` or `AdminLayoutComponent` based on the route.
- For `AdminLayoutComponent` to be secure, an `adminGuard` must be created.
- For `adminGuard` to function, it needs to know the user's role. Therefore, the `AuthService` and `User` models must be updated to expect and store role information returned by the backend (from M1).

## 3. Caveats
- It is assumed that the backend's `/api/auth/login` and `/api/auth/profile` endpoints have been updated (in M1) to return a `roles` or `role` field in the JSON response. If they haven't, the backend needs to be updated or the frontend will have to decode the JWT token directly to extract the roles.
- We assume `ROLE_ADMIN` is the exact string used by the backend.

## 4. Conclusion
**Recommended Actionable Fix Strategy:**

1. **Update User Models:**
   - In `src/app/services/auth.service.ts`, add `roles: string[]` to `AuthResponse`.
   - In `src/app/models/birthday.model.ts`, add `roles: string[]` to the `User` interface.
   - Update `AuthService.saveSession()` to map `roles` from the response to the user object.

2. **Create Admin Guard:**
   - Create `src/app/guards/admin.guard.ts`.
   - The guard should verify `authService.isAuthenticated()` AND `authService.currentUser()?.roles?.includes('ROLE_ADMIN')`.
   - Redirect to `/dashboard` (if lacking permissions) or `/login` (if unauthenticated).

3. **Layout Separation:**
   - Extract the header, footer, and main container from `app.html` into a new `src/app/layouts/main-layout/main-layout.component`. Move the associated logic (theme, language, logout) from `app.ts` to this new component.
   - Create `src/app/layouts/admin-layout/admin-layout.component` as a placeholder for the admin interface.
   - Simplify `app.ts` and `app.html` to only contain a root `<router-outlet>` and global overlays (e.g., `<app-toast-container>`).

4. **Refactor Routing (`src/app/app.routes.ts`):**
   - Restructure the routes using the layout wrapper pattern:
     ```typescript
     export const routes: Routes = [
       { path: 'login', ... },
       {
         path: 'admin',
         loadComponent: () => import('./layouts/admin-layout/admin-layout.component').then(m => m.AdminLayoutComponent),
         canActivate: [adminGuard],
         children: [
           // M4 Admin views will go here
         ]
       },
       {
         path: '',
         loadComponent: () => import('./layouts/main-layout/main-layout.component').then(m => m.MainLayoutComponent),
         children: [
           // Existing dashboard, profile, privacy routes go here
         ]
       },
       { path: '**', redirectTo: 'dashboard' }
     ];
     ```

## 5. Verification Method
- Build the frontend: `npm run build` in `d:\formations_personnelles\time2wish-ai\frontend`.
- Test routing: Log in as a normal user and navigate to `/admin`; the `adminGuard` should redirect to `/dashboard`.
- Log in as an admin; navigating to `/admin` should display the `AdminLayoutComponent`.
- Check that existing routes (`/dashboard`, `/privacy`) still display the standard header and footer via `MainLayoutComponent`.
