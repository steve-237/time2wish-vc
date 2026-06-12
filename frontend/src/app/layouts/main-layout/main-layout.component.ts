import { Component, signal, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslationService, Language } from '../../services/translation.service';
import { AuthService } from '../../services/auth.service';
import { NotificationPanelComponent } from '../../components/notification-panel/notification-panel.component';
import { PwaService } from '../../services/pwa.service';
import { PricingComponent } from '../../pages/pricing/pricing.component';
import { UiService } from '../../services/ui.service';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, NotificationPanelComponent, PricingComponent],
  template: `
    @if (authService.isAuthenticated()) {
    <header class="glass-header">
      <div class="header-content flex-between gap-md">
        
        <!-- Logo -->
        <a routerLink="/dashboard" class="logo-link flex-center gap-sm">
          <span class="gradient-text">Time2Wish</span>
          <span>🎂</span>
        </a>

        <!-- Toolbar actions -->
        <div class="toolbar-actions flex-center gap-sm">
          
          <!-- Language Selector Custom Dropdown -->
          <div class="custom-lang-menu-container lang-menu-wrapper">
            <button class="custom-lang-btn lang-btn" (click)="isLangMenuOpen.set(!isLangMenuOpen())">
              <img [src]="getActiveFlagUrl()" alt="flag" class="flag-icon lang-flag">
              <span class="material-symbols-outlined lang-arrow" [class.rotated]="isLangMenuOpen()">expand_more</span>
            </button>

            @if (isLangMenuOpen()) {
            <div class="custom-lang-dropdown">
              @for (lang of languages; track lang.code) {
              <div class="lang-option" (click)="setLanguage(lang.code)" [class.active]="t9n.currentLang() === lang.code">
                <img [src]="lang.flagUrl" alt="flag" class="flag-icon">
                <span class="label">{{ lang.label }}</span>
              </div>
              }
            </div>
            }
          </div>

          <!-- Backdrop to close the menu when clicking outside -->
          @if (isLangMenuOpen()) {
          <div class="lang-backdrop" (click)="isLangMenuOpen.set(false)"></div>
          }

          <!-- Admin Panel Button -->
          @if (isAdmin()) {
          <a routerLink="/admin" class="btn-secondary admin-btn" title="Administration">
            <span class="material-symbols-outlined admin-icon">admin_panel_settings</span>
            <span class="hide-mobile">Admin</span>
          </a>
          }

          <!-- Install PWA Button -->
          @if (pwaService.canInstall()) {
          <button (click)="pwaService.installApp()" class="btn-premium pwa-btn">
            <span class="material-symbols-outlined pwa-icon">install_desktop</span>
            <span class="hide-mobile">{{ t9n.t('nav.install') || 'Installer' }}</span>
          </button>
          }

          <!-- Pricing/Plans Button -->
          <button (click)="uiService.isPricingModalOpen.set(true)" class="icon-btn plans-btn-small" title="Forfaits" style="color: #fbbf24;">
            <span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">star</span>
          </button>

          <!-- App mode switch -->
          <button (click)="cycleAppMode()" class="icon-btn theme-toggle" [title]="appMode() === 'light' ? 'Mode Sombre' : (appMode() === 'dark' ? 'Mode OLED' : 'Mode Clair')">
            @if (appMode() === 'light') {
            <span class="material-symbols-outlined">dark_mode</span>
            } @else if (appMode() === 'dark') {
            <span class="material-symbols-outlined">contrast</span>
            } @else {
            <span class="material-symbols-outlined">light_mode</span>
            }
          </button>

          <!-- Notifications Panel -->
          <app-notification-panel></app-notification-panel>

          <!-- Profile dropdown / User Menu -->
          <a routerLink="/dashboard/profile" class="user-profile-menu flex-center gap-sm profile-link">
            <img [src]="authService.currentUser()?.avatarUrl" alt="Avatar" class="user-avatar">
            <div class="user-info">
               <span class="user-name">{{ authService.currentUser()?.fullName }}</span>
               <span class="user-email">{{ authService.currentUser()?.email }}</span>
            </div>
          </a>

          <!-- Logout -->
          <button (click)="onLogout()" class="btn-secondary logout-btn">
            <span class="material-symbols-outlined logout-icon">logout</span>
            <span class="logout-text">{{ t9n.t('nav.logout') }}</span>
          </button>
        </div>

      </div>
    </header>
    }

    <!-- Main content routing window -->
    <main class="main-container">
      <router-outlet></router-outlet>
      @if (uiService.isPricingModalOpen()) {
        <app-pricing (close)="uiService.isPricingModalOpen.set(false)"></app-pricing>
      }
    </main>

    <!-- Footer -->
    <footer class="app-footer">
      <div class="footer-content flex-center">
        <p>© 2026 Time2Wish. {{ t9n.t('footer.tagline') }}</p>
        <div class="footer-links flex-center gap-md">
          <a routerLink="/privacy" class="footer-link">{{ t9n.t('footer.privacy') }}</a>
          <span class="separator">•</span>
          <a routerLink="/terms" class="footer-link">{{ t9n.t('footer.terms') }}</a>
          <span class="separator">•</span>
          <a routerLink="/support" class="footer-link">{{ t9n.t('footer.support') }}</a>
        </div>
      </div>
    </footer>
  `
})
export class MainLayoutComponent {
  authService = inject(AuthService);
  router = inject(Router);
  t9n = inject(TranslationService);
  pwaService = inject(PwaService);

  uiService = inject(UiService);

  readonly languages: { code: Language; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);
  appMode = signal<'light' | 'dark' | 'oled'>('light');

  constructor() {
    const storedMode = localStorage.getItem('t2w_app_mode') as 'light' | 'dark' | 'oled';
    if (storedMode) {
      this.appMode.set(storedMode);
    }
  }

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  setLanguage(lang: Language) {
    this.t9n.setLanguage(lang);
    this.isLangMenuOpen.set(false);
  }

  setAppMode(mode: 'light' | 'dark' | 'oled') {
    this.appMode.set(mode);
    document.body.classList.remove('dark-theme', 'oled-theme');
    
    if (mode === 'dark') {
      document.body.classList.add('dark-theme');
    } else if (mode === 'oled') {
      document.body.classList.add('oled-theme');
    }
    
    localStorage.setItem('t2w_app_mode', mode);
  }

  cycleAppMode() {
    if (this.appMode() === 'light') {
      this.setAppMode('dark');
    } else if (this.appMode() === 'dark') {
      this.setAppMode('oled');
    } else {
      this.setAppMode('light');
    }
  }

  isAdmin(): boolean {
    const user = this.authService.currentUser();
    return user?.roles?.includes('ROLE_ADMIN') ?? false;
  }

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/login']);
    });
  }
}
