import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { createEnvironmentInjector, EnvironmentInjector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { of, throwError } from 'rxjs';
import { AuthService } from './auth.service';
import { environment } from '../../environments/environment';

describe('AuthService', () => {
  let service: AuthService;
  let mockHttp: any;
  let injector: EnvironmentInjector;

  const mockAuthResponse = {
    token: 'fake-jwt-token',
    refreshToken: 'fake-refresh-uuid',
    id: 1,
    email: 'test@example.com',
    fullName: 'Test User',
    roles: ['ROLE_USER'],
    plan: 'BASIC'
  };

  function createService(): AuthService {
    mockHttp = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn()
    };

    injector = createEnvironmentInjector([
      { provide: HttpClient, useValue: mockHttp }
    ]);

    return runInInjectionContext(injector, () => new AuthService());
  }

  beforeEach(() => {
    localStorage.clear();
    service = createService();
  });

  afterEach(() => {
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('should be created and start unauthenticated if localStorage is empty', () => {
    expect(service).toBeTruthy();
    expect(service.isAuthenticated()).toBe(false);
    expect(service.currentUser()).toBeNull();
    expect(service.accessToken()).toBeNull();
  });

  it('should restore session from localStorage if present at creation', () => {
    localStorage.setItem('t2w_access_token', 'saved-access-token');
    localStorage.setItem('t2w_refresh_token', 'saved-refresh-token');
    localStorage.setItem('t2w_user_profile', JSON.stringify(mockAuthResponse));

    const restoredService = createService();
    expect(restoredService.isAuthenticated()).toBe(true);
    expect(restoredService.accessToken()).toBe('saved-access-token');
    expect(restoredService.getStoredRefreshToken()).toBe('saved-refresh-token');
    expect(restoredService.currentUser()?.email).toBe('test@example.com');
  });

  describe('login', () => {
    it('should authenticate user and save session on successful login', () => {
      mockHttp.post.mockReturnValue(of(mockAuthResponse));

      service.login('test@example.com', 'password123').subscribe((success) => {
        expect(success).toBe(true);
        expect(service.isAuthenticated()).toBe(true);
        expect(service.currentUser()?.email).toBe('test@example.com');
        expect(service.accessToken()).toBe('fake-jwt-token');

        expect(localStorage.getItem('t2w_access_token')).toBe('fake-jwt-token');
        expect(localStorage.getItem('t2w_refresh_token')).toBe('fake-refresh-uuid');
        expect(localStorage.getItem('t2w_user_profile')).toContain('Test User');
      });

      expect(mockHttp.post).toHaveBeenCalledWith(
        `${environment.apiUrl}/auth/login`,
        { email: 'test@example.com', password: 'password123' },
        { withCredentials: true }
      );
    });

    it('should return false on failed login', () => {
      mockHttp.post.mockReturnValue(throwError(() => new Error('Unauthorized')));

      service.login('wrong@example.com', 'wrongpass').subscribe((success) => {
        expect(success).toBe(false);
        expect(service.isAuthenticated()).toBe(false);
      });
    });
  });

  describe('refreshSession', () => {
    it('should call refresh endpoint with stored refresh token if present', () => {
      localStorage.setItem('t2w_access_token', 'old-access-token');
      localStorage.setItem('t2w_refresh_token', 'saved-refresh-uuid');
      localStorage.setItem('t2w_user_profile', JSON.stringify({ id: 1, email: 'test@test.com', fullName: 'Test', roles: [] }));

      const currentService = createService();
      mockHttp.post.mockReturnValue(of(mockAuthResponse));

      currentService.refreshSession().subscribe((success) => {
        expect(success).toBe(true);
        expect(currentService.accessToken()).toBe('fake-jwt-token');
        expect(localStorage.getItem('t2w_access_token')).toBe('fake-jwt-token');
        expect(localStorage.getItem('t2w_refresh_token')).toBe('fake-refresh-uuid');
      });

      expect(mockHttp.post).toHaveBeenCalledWith(
        `${environment.apiUrl}/auth/refresh`,
        { refreshToken: 'saved-refresh-uuid' },
        { withCredentials: true }
      );
    });

    it('should clear session if refresh endpoint fails', () => {
      localStorage.setItem('t2w_access_token', 'old-access-token');
      localStorage.setItem('t2w_refresh_token', 'invalid-refresh-uuid');
      localStorage.setItem('t2w_user_profile', JSON.stringify({ id: 1, email: 'test@test.com', fullName: 'Test', roles: [] }));

      const currentService = createService();
      mockHttp.post.mockReturnValue(throwError(() => new Error('Invalid token')));

      currentService.refreshSession().subscribe((success) => {
        expect(success).toBe(false);
        expect(currentService.isAuthenticated()).toBe(false);
        expect(localStorage.getItem('t2w_access_token')).toBeNull();
        expect(localStorage.getItem('t2w_refresh_token')).toBeNull();
      });
    });
  });

  describe('logout', () => {
    it('should clear session and call logout endpoint', () => {
      localStorage.setItem('t2w_access_token', 'token');
      localStorage.setItem('t2w_refresh_token', 'refresh-token');
      localStorage.setItem('t2w_user_profile', JSON.stringify(mockAuthResponse));

      const currentService = createService();
      mockHttp.post.mockReturnValue(of({}));

      currentService.logout().subscribe((success) => {
        expect(success).toBe(true);
        expect(currentService.isAuthenticated()).toBe(false);
        expect(localStorage.getItem('t2w_access_token')).toBeNull();
        expect(localStorage.getItem('t2w_refresh_token')).toBeNull();
        expect(localStorage.getItem('t2w_user_profile')).toBeNull();
      });

      expect(mockHttp.post).toHaveBeenCalledWith(
        `${environment.apiUrl}/auth/logout`,
        {},
        { withCredentials: true }
      );
    });
  });
});
