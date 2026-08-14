import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule, Router, ActivatedRoute } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { ToastService } from '../../services/toast.service';
import { GoogleSyncService } from '../../services/google-sync.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './login.html',
  styleUrl: './login.scss'
})
export class Login implements OnInit {
  authService = inject(AuthService);
  googleSyncService = inject(GoogleSyncService);
  t9n = inject(TranslationService);
  router = inject(Router);
  route = inject(ActivatedRoute);
  toastService = inject(ToastService);

  readonly languages: { code: string; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);

  isLoginTab = signal<boolean>(true);
  
  email = signal<string>('');
  password = signal<string>('');
  fullName = signal<string>('');
  errorMessage = signal<string>('');
  isLoading = signal<boolean>(false);

  // Forgot password state
  isForgotModalOpen = signal<boolean>(false);
  forgotEmail = signal<string>('');
  isForgotEmailSent = signal<boolean>(false);
  timeoutMessage = signal<string>('');

  constructor() {
    // Redirect if already authenticated
    if (this.authService.isAuthenticated()) {
      this.router.navigate(['/dashboard']);
    }
  }

  ngOnInit() {
    // Check for timeout reason
    this.route.queryParams.subscribe(params => {
      if (params['reason'] === 'timeout') {
        const lang = this.t9n.currentLang();
        const messages: Record<string, string> = {
          fr: 'Vous avez été déconnecté pour cause d\'inactivité (10 minutes).',
          en: 'You have been disconnected due to inactivity (10 minutes).',
          de: 'Sie wurden wegen Inaktivität abgemeldet (10 Minuten).'
        };
        const msg = messages[lang] || messages['fr'];
        this.timeoutMessage.set(msg);
      }
    });
  }

  toggleTab() {
    this.isLoginTab.update(val => !val);
    this.errorMessage.set('');
  }

  setLanguage(lang: string) {
    this.t9n.setLanguage(lang as any);
    this.isLangMenuOpen.set(false);
  }

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  openForgotPassword() {
    this.forgotEmail.set(this.email()); // pre-fill if available
    this.isForgotEmailSent.set(false);
    this.isForgotModalOpen.set(true);
  }

  closeForgotPassword() {
    this.isForgotModalOpen.set(false);
    this.isForgotEmailSent.set(false);
  }

  sendForgotPassword() {
    if (!this.forgotEmail()) {
      alert(this.t9n.currentLang() === 'en' ? 'Please enter an email address.' : 'Veuillez entrer une adresse email.');
      return;
    }
    // Simulation
    this.isForgotEmailSent.set(true);
  }

  onSubmit() {
    this.errorMessage.set('');

    if (!this.email() || !this.password()) {
      this.errorMessage.set('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (this.isLoginTab()) {
      // Login flow
      this.isLoading.set(true);
      this.authService.login(this.email(), this.password()).subscribe(success => {
        this.isLoading.set(false);
        if (success) {
          this.router.navigate(['/dashboard']);
        } else {
          this.errorMessage.set('Identifiants incorrects.');
        }
      });
    } else {
      // Register flow
      if (!this.fullName()) {
        this.errorMessage.set('Le nom complet est obligatoire.');
        return;
      }
      
      this.isLoading.set(true);
      this.authService.register(this.email(), this.password(), this.fullName()).subscribe(success => {
        if (success) {
          // Log in automatically after registration
          this.authService.login(this.email(), this.password()).subscribe(loginSuccess => {
            this.isLoading.set(false);
            if (loginSuccess) {
              this.router.navigate(['/dashboard']);
            } else {
              this.errorMessage.set('Erreur de connexion automatique.');
            }
          });
        } else {
          this.isLoading.set(false);
          this.errorMessage.set('Cet email est déjà enregistré.');
        }
      });
    }
  }

  loginWithGoogle() {
    this.isLoading.set(true);
    this.googleSyncService.getAuthUrl().subscribe({
      next: (res) => {
        if (res && res.url) {
          window.location.href = res.url;
        } else {
          this.isLoading.set(false);
          this.toastService.error('Erreur: URL d\'autorisation Google non disponible.');
        }
      },
      error: () => {
        this.isLoading.set(false);
        this.toastService.error(
          this.t9n.currentLang() === 'en'
            ? 'Error redirecting to Google.'
            : (this.t9n.currentLang() === 'de' ? 'Fehler bei der Weiterleitung zu Google.' : 'Erreur lors de la redirection vers Google.')
        );
      }
    });
  }
}
