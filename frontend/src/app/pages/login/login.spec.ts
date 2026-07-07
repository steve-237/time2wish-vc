import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Login } from './login';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { of } from 'rxjs';
import { Router } from '@angular/router';

describe('Login Component', () => {
  let component: Login;
  let fixture: ComponentFixture<Login>;
  let mockAuthService: any;
  let mockRouter: any;

  beforeEach(async () => {
    mockAuthService = {
      isAuthenticated: vi.fn().mockReturnValue(false),
      login: vi.fn().mockReturnValue(of(true)),
      register: vi.fn().mockReturnValue(of(true))
    };

    const mockTranslationService = {
      currentLang: vi.fn().mockReturnValue('fr'),
      setLanguage: vi.fn(),
      t: vi.fn((key: string) => key)
    };

    const mockToastService = {
      success: vi.fn(),
      error: vi.fn()
    };

    mockRouter = {
      navigate: vi.fn()
    };

    await TestBed.configureTestingModule({
      imports: [Login, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService },
        { provide: Router, useValue: mockRouter }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(Login);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the login component', () => {
    expect(component).toBeTruthy();
  });

  it('should redirect to dashboard if already authenticated', () => {
    mockAuthService.isAuthenticated.mockReturnValue(true);
    
    // Re-create component to trigger constructor logic
    const fixture2 = TestBed.createComponent(Login);
    expect(mockRouter.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('should handle login submission successfully', () => {
    component.isLoginTab.set(true);
    component.email.set('test@time2wish.com');
    component.password.set('password123');

    component.onSubmit();

    expect(mockAuthService.login).toHaveBeenCalledWith('test@time2wish.com', 'password123');
    expect(mockRouter.navigate).toHaveBeenCalledWith(['/dashboard']);
    expect(component.errorMessage()).toBe('');
  });

  it('should show error message on login failure', () => {
    component.isLoginTab.set(true);
    component.email.set('test@time2wish.com');
    component.password.set('wrong');
    mockAuthService.login.mockReturnValue(of(false));

    component.onSubmit();

    expect(mockAuthService.login).toHaveBeenCalledWith('test@time2wish.com', 'wrong');
    expect(component.errorMessage()).toBe('Identifiants incorrects.');
    expect(mockRouter.navigate).not.toHaveBeenCalled();
  });

  it('should handle register submission successfully', () => {
    component.isLoginTab.set(false);
    component.email.set('new@time2wish.com');
    component.password.set('password123');
    component.fullName.set('New User');

    component.onSubmit();

    expect(mockAuthService.register).toHaveBeenCalledWith('new@time2wish.com', 'password123', 'New User');
    expect(mockAuthService.login).toHaveBeenCalledWith('new@time2wish.com', 'password123');
    expect(mockRouter.navigate).toHaveBeenCalledWith(['/dashboard']);
  });

  it('should require all fields for registration', () => {
    component.isLoginTab.set(false);
    component.email.set('new@time2wish.com');
    component.password.set('password123');
    component.fullName.set(''); // Empty full name

    component.onSubmit();

    expect(mockAuthService.register).not.toHaveBeenCalled();
    expect(component.errorMessage()).toBe('Le nom complet est obligatoire.');
  });
});
