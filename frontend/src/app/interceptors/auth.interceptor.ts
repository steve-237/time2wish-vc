import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';
import { catchError, switchMap } from 'rxjs/operators';
import { throwError } from 'rxjs';
import { Router } from '@angular/router';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);
  const token = authService.accessToken();

  // If token exists, append Bearer Authorization header
  let authReq = req;
  if (token) {
    authReq = req.clone({
      setHeaders: {
        Authorization: `Bearer ${token}`
      }
    });
  }

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      const isAuthEndpoint = req.url.includes('/auth/login') ||
                             req.url.includes('/auth/refresh') ||
                             req.url.includes('/auth/register');

      if (error.status === 401 && !isAuthEndpoint) {
        return authService.refreshSession().pipe(
          switchMap(success => {
            if (success && authService.accessToken()) {
              const retryReq = req.clone({
                setHeaders: {
                  Authorization: `Bearer ${authService.accessToken()}`
                }
              });
              return next(retryReq);
            }
            authService.logout().subscribe(() => {
              router.navigate(['/login']);
            });
            return throwError(() => error);
          }),
          catchError(refreshError => {
            authService.logout().subscribe(() => {
              router.navigate(['/login']);
            });
            return throwError(() => refreshError);
          })
        );
      }

      return throwError(() => error);
    })
  );
};
