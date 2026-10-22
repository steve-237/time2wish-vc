import '@angular/compiler';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { createEnvironmentInjector, EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { HttpRequest, HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { of, throwError } from 'rxjs';
import { authInterceptor } from './auth.interceptor';
import { AuthService } from '../services/auth.service';

describe('authInterceptor', () => {
  let authServiceMock: any;
  let routerMock: any;
  let injector: EnvironmentInjector;

  beforeEach(() => {
    authServiceMock = {
      accessToken: vi.fn().mockReturnValue('mock-token-xyz'),
      refreshSession: vi.fn().mockReturnValue(of(true)),
      logout: vi.fn().mockReturnValue(of(true))
    };

    routerMock = {
      navigate: vi.fn()
    };

    injector = createEnvironmentInjector([
      { provide: AuthService, useValue: authServiceMock },
      { provide: Router, useValue: routerMock }
    ]);
  });

  it('should add Authorization Bearer header if token exists', () => {
    const req = new HttpRequest('GET', '/api/users/me');
    let capturedReq: any;
    const next = (r: HttpRequest<any>) => {
      capturedReq = r;
      return of({} as any);
    };

    runInInjectionContext(injector, () => {
      authInterceptor(req, next).subscribe();
    });

    expect(capturedReq.headers.get('Authorization')).toBe('Bearer mock-token-xyz');
  });

  it('should attempt refreshSession and retry request on 401 for normal endpoints', () => {
    const req = new HttpRequest('GET', '/api/birthdays');
    let callCount = 0;
    let retriedReq: any;

    const next = (r: HttpRequest<any>) => {
      callCount++;
      if (callCount === 1) {
        return throwError(() => new HttpErrorResponse({ status: 401, statusText: 'Unauthorized' }));
      }
      retriedReq = r;
      return of({} as any);
    };

    runInInjectionContext(injector, () => {
      authInterceptor(req, next).subscribe();
    });

    expect(authServiceMock.refreshSession).toHaveBeenCalled();
    expect(callCount).toBe(2);
    expect(retriedReq).toBeDefined();
  });

  it('should logout and redirect to login if refresh fails on 401', () => {
    authServiceMock.refreshSession.mockReturnValue(of(false));

    const req = new HttpRequest('GET', '/api/birthdays');
    const next = () => throwError(() => new HttpErrorResponse({ status: 401, statusText: 'Unauthorized' }));

    let errorReceived: any;
    runInInjectionContext(injector, () => {
      authInterceptor(req, next).subscribe({
        error: (err) => { errorReceived = err; }
      });
    });

    expect(authServiceMock.refreshSession).toHaveBeenCalled();
    expect(authServiceMock.logout).toHaveBeenCalled();
    expect(routerMock.navigate).toHaveBeenCalledWith(['/login']);
    expect(errorReceived.status).toBe(401);
  });

  it('should not attempt refresh on /auth/login 401', () => {
    const req = new HttpRequest('POST', '/api/auth/login', {});
    const next = () => throwError(() => new HttpErrorResponse({ status: 401, statusText: 'Unauthorized' }));

    runInInjectionContext(injector, () => {
      authInterceptor(req, next).subscribe({
        error: () => {}
      });
    });

    expect(authServiceMock.refreshSession).not.toHaveBeenCalled();
  });
});
