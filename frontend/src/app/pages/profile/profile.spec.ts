import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Profile } from './profile';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { RouterTestingModule } from '@angular/router/testing';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { ThemeService } from '../../services/theme.service';
import { of } from 'rxjs';
import { Router } from '@angular/router';

describe('Profile Component', () => {
  let component: Profile;
  let fixture: ComponentFixture<Profile>;
  let mockAuthService: any;
  let mockRouter: any;
  let mockToastService: any;
  let mockThemeService: any;

  beforeEach(async () => {
    mockAuthService = {
      currentUser: vi.fn().mockReturnValue({
        fullName: 'John Doe',
        bio: 'Hello world',
        avatarUrl: 'http://avatar.com/john.png'
      }),
      updateProfile: vi.fn().mockReturnValue(of(true)),
      updatePassword: vi.fn().mockReturnValue(of(true))
    };

    const mockTranslationService = {
      currentLang: vi.fn().mockReturnValue('fr'),
      setLanguage: vi.fn(),
      t: vi.fn((key: string) => key)
    };

    mockToastService = {
      success: vi.fn(),
      error: vi.fn()
    };

    mockThemeService = {
      setAppMode: vi.fn(),
      setColorTheme: vi.fn()
    };

    mockRouter = {
      navigate: vi.fn()
    };

    await TestBed.configureTestingModule({
      imports: [Profile, HttpClientTestingModule, RouterTestingModule],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        { provide: TranslationService, useValue: mockTranslationService },
        { provide: ToastService, useValue: mockToastService },
        { provide: ThemeService, useValue: mockThemeService },
        { provide: Router, useValue: mockRouter }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(Profile);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create the profile component', () => {
    expect(component).toBeTruthy();
  });

  it('should load user data on init', () => {
    expect(component.fullName()).toBe('John Doe');
    expect(component.bio()).toBe('Hello world');
    expect(component.avatarUrl()).toBe('http://avatar.com/john.png');
  });

  it('should save profile successfully', () => {
    component.fullName.set('Jane Doe');
    component.bio.set('New bio');
    
    component.onSaveProfile();

    expect(mockAuthService.updateProfile).toHaveBeenCalledWith('Jane Doe', 'New bio', 'http://avatar.com/john.png');
    expect(mockToastService.success).toHaveBeenCalled();
  });

  it('should require full name to save profile', () => {
    component.fullName.set('');
    
    component.onSaveProfile();

    expect(mockAuthService.updateProfile).not.toHaveBeenCalled();
    expect(mockToastService.error).toHaveBeenCalledWith('Le nom complet est obligatoire.');
  });

  it('should show error if password fields are missing', () => {
    component.currentPassword.set('pass');
    component.newPassword.set('');
    component.confirmPassword.set('');
    
    component.onUpdatePassword();

    expect(mockAuthService.updatePassword).not.toHaveBeenCalled();
    expect(mockToastService.error).toHaveBeenCalledWith('Veuillez remplir tous les champs de mot de passe.');
  });

  it('should show error if new passwords do not match', () => {
    component.currentPassword.set('oldpass');
    component.newPassword.set('newpass');
    component.confirmPassword.set('newpass2');
    
    component.onUpdatePassword();

    expect(mockAuthService.updatePassword).not.toHaveBeenCalled();
    expect(mockToastService.error).toHaveBeenCalledWith('Les nouveaux mots de passe ne correspondent pas.');
  });

  it('should update password successfully', () => {
    component.currentPassword.set('oldpass');
    component.newPassword.set('newpass');
    component.confirmPassword.set('newpass');
    
    component.onUpdatePassword();

    expect(mockAuthService.updatePassword).toHaveBeenCalledWith('oldpass', 'newpass');
    expect(mockToastService.success).toHaveBeenCalled();
    expect(component.currentPassword()).toBe('');
    expect(component.newPassword()).toBe('');
    expect(component.confirmPassword()).toBe('');
  });
});
