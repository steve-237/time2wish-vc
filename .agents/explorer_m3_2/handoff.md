# Handoff Report: Frontend Admin Layout Strategy

## Observation
1. **Routing structure**: The current application layout (Header, Notification Panel, Footer) is hardcoded directly into `src/app/app.html` (`app.component.ts`). The `src/app/app.routes.ts` file maps routes directly to pages (like `/dashboard`) without utilizing dedicated layout wrapper components.
2. **Authentication Service**: `src/app/services/auth.service.ts` uses an `AuthResponse` interface and a `User` model (from `src/app/models/birthday.model.ts`) that currently lack any role-based properties. The token is saved as an opaque string without JWT decoding logic in the frontend.
3. **Existing Guard**: `src/app/guards/auth.guard.ts` only checks for the presence of a user session (`authService.isAuthenticated()`) and does not verify specific roles.
4. **Project Requirements**: M3 requires a "Separate Angular layout dedicated to administration" and "Route Guards protecting admin routes".

## Logic Chain
1. Because `app.html` directly contains the user-facing header and footer, navigating to an admin route right now would display the user layout. Therefore, the global layout elements must be extracted from `app.component` into a dedicated `MainLayoutComponent` (for users) and an `AdminLayoutComponent` (for admins) to fulfill the "distinct layout" requirement.
2. Because `app.routes.ts` is flat, it needs to be refactored to use layout wrapper routes, e.g., an `admin` path pointing to `AdminLayoutComponent` which has its own `children` routes.
3. Since the frontend doesn't currently parse the JWT and instead relies on the backend sending explicit user data in `AuthResponse`, the simplest and most consistent way to verify roles is to update `AuthResponse` and the `User` model to include a `roles: string[]` or `role: string` property.
4. To fulfill the "Route Guard" requirement, a new `admin.guard.ts` needs to be created. It will inject `AuthService` and check if the current user has the `ROLE_ADMIN` role before allowing activation of the admin layout routes.

## Caveats
- I did not modify the code as per my read-only constraint.
- I assumed the backend `AuthResponse` can easily be updated to include a `roles` array or `role` string since the backend is already sending explicit user data (like `email`, `fullName`) alongside the token.
- Refactoring `app.html` to a layout-based routing will require moving CSS and template code from `app.component` to the new layout components.

## Conclusion
The recommended strategy involves three steps:
1. **Layout Refactoring**: Extract the existing `app.html` template into a `MainLayoutComponent`. Create an `AdminLayoutComponent`. Update `app.component.html` to only contain `<router-outlet>` and `app-toast-container`. Update `app.routes.ts` to nest routes under these layout components.
2. **Auth Model Update**: Update `AuthResponse` in `auth.service.ts` and the `User` model in `birthday.model.ts` to include `roles: string[]`. Update `saveSession` to copy this property.
3. **Admin Guard**: Implement `src/app/guards/admin.guard.ts` to verify `authService.isAuthenticated()` AND `authService.currentUser()?.roles?.includes('ROLE_ADMIN')`. Apply this guard to the admin layout route in `app.routes.ts`.

## Verification Method
- **Code Inspection**: Verify `app.routes.ts` contains distinct layout routes.
- **Run the App**: Log in as a normal user and attempt to navigate to an admin route (e.g., `/admin`) - should redirect or return 403.
- **Log in as Admin**: Verify the admin routes load successfully and the layout UI is distinct from the regular user dashboard.
