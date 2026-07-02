import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { AuthService } from './auth.service';
import { environment } from '../../environments/environment';

describe('AuthService', () => {
  let service: AuthService;
  let httpMock: HttpTestingController;

  const mockAuthResponse = {
    token: 'fake-jwt-token',
    id: 1,
    email: 'test@example.com',
    fullName: 'Test User',
    roles: ['ROLE_USER'],
    plan: 'BASIC'
  };

  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear();

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [AuthService]
    });
    service = TestBed.inject(AuthService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    localStorage.clear();
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should start with no user authenticated if localStorage is empty', () => {
    expect(service.isAuthenticated()).toBe(false);
    expect(service.currentUser()).toBeNull();
    expect(service.accessToken()).toBeNull();
  });

  describe('login', () => {
    it('should authenticate user and save session on successful login', () => {
      service.login('test@example.com', 'password123').subscribe((success) => {
        expect(success).toBe(true);
        expect(service.isAuthenticated()).toBe(true);
        expect(service.currentUser()?.email).toBe('test@example.com');
        expect(service.accessToken()).toBe('fake-jwt-token');
        
        // Verify localStorage
        expect(localStorage.getItem('t2w_access_token')).toBe('fake-jwt-token');
        expect(localStorage.getItem('t2w_user_profile')).toContain('Test User');
      });

      const req = httpMock.expectOne(`${environment.apiUrl}/auth/login`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({ email: 'test@example.com', password: 'password123' });
      req.flush(mockAuthResponse);
    });

    it('should return false on failed login', () => {
      service.login('wrong@example.com', 'wrongpass').subscribe((success) => {
        expect(success).toBe(false);
        expect(service.isAuthenticated()).toBe(false);
      });

      const req = httpMock.expectOne(`${environment.apiUrl}/auth/login`);
      req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });
    });
  });

  describe('logout', () => {
    it('should clear session on logout', () => {
      // First setup a fake session
      localStorage.setItem('t2w_access_token', 'token');
      localStorage.setItem('t2w_user_profile', JSON.stringify(mockAuthResponse));
      
      // We must recreate the service so it picks up the localStorage during init signals
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({
        imports: [HttpClientTestingModule],
        providers: [AuthService]
      });
      const newService = TestBed.inject(AuthService);
      const newHttpMock = TestBed.inject(HttpTestingController);

      expect(newService.isAuthenticated()).toBe(true);

      newService.logout().subscribe((success) => {
        expect(success).toBe(true);
        expect(newService.isAuthenticated()).toBe(false);
        expect(localStorage.getItem('t2w_access_token')).toBeNull();
      });

      const req = newHttpMock.expectOne(`${environment.apiUrl}/auth/logout`);
      expect(req.request.method).toBe('POST');
      req.flush({});
    });
  });

  describe('refreshSession', () => {
    it('should recover session if token is in localStorage and refresh API succeeds', () => {
      localStorage.setItem('t2w_access_token', 'old-token');
      localStorage.setItem('t2w_user_profile', JSON.stringify({ id: 1, email: 'test@test.com', fullName: 'Test', roles: [] }));

      // Re-init
      TestBed.resetTestingModule();
      TestBed.configureTestingModule({ imports: [HttpClientTestingModule], providers: [AuthService] });
      const newService = TestBed.inject(AuthService);
      const newHttpMock = TestBed.inject(HttpTestingController);

      newService.refreshSession().subscribe((success) => {
        expect(success).toBe(true);
        expect(newService.accessToken()).toBe('fake-jwt-token'); // updated from API
      });

      const req = newHttpMock.expectOne(`${environment.apiUrl}/auth/refresh`);
      expect(req.request.method).toBe('POST');
      req.flush(mockAuthResponse);
    });
  });
});
