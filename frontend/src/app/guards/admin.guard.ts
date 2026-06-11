import { inject } from '@angular/core';
import { Router, type CanActivateFn } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const adminGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const user = authService.currentUser();
  if (user && user.roles && (user.roles.includes('ROLE_ADMIN') || user.roles.includes('ROLE_SUPERADMIN'))) {
    return true;
  }

  // Not an admin, redirect to admin login
  return router.createUrlTree(['/admin/login']);
};
