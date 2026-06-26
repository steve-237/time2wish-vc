import { Component, signal, inject, OnInit } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslationService, Language } from '../../services/translation.service';
import { AuthService } from '../../services/auth.service';
import { NotificationPanelComponent } from '../../components/notification-panel/notification-panel.component';
import { PwaService } from '../../services/pwa.service';
import { PricingComponent } from '../../pages/pricing/pricing.component';
import { UiService } from '../../services/ui.service';
import { ThemeService } from '../../services/theme.service';

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
          
          <!-- Pricing/Plans Button -->
          <button (click)="uiService.isPricingModalOpen.set(true)" class="premium-nav-btn" [title]="t9n.t('nav.plans') || 'Forfaits'">
            <span class="material-symbols-outlined">diamond</span>
            <span class="hide-mobile">{{ t9n.t('nav.plans') || 'Forfaits' }}</span>
          </button>

          <!-- Install PWA Button -->
          @if (pwaService.canInstall()) {
          <button (click)="pwaService.installApp()" class="btn-secondary pwa-btn" title="Installer l'application" style="padding: 8px; border-radius: 50%;">
            <span class="material-symbols-outlined pwa-icon" style="margin:0;">install_desktop</span>
          </button>
          }

          <!-- Notifications Panel -->
          <app-notification-panel></app-notification-panel>

          <!-- Profile Dropdown Menu Container -->
          <div class="profile-menu-container" style="position: relative;">
            <button class="profile-toggle-btn flex-center" (click)="isProfileMenuOpen.set(!isProfileMenuOpen())" style="background: none; border: none; cursor: pointer; padding: 4px; border-radius: 30px; gap: 4px; transition: background 0.2s;">
              <img [src]="authService.currentUser()?.avatarUrl || 'https://ui-avatars.com/api/?name=' + (authService.currentUser()?.fullName || 'U') + '&background=random'" alt="Avatar" class="user-avatar" style="width: 36px; height: 36px; border-radius: 50%; border: 2px solid var(--border-card);">
              <span class="material-symbols-outlined profile-chevron" [style.transform]="isProfileMenuOpen() ? 'rotate(180deg)' : 'none'" style="transition: transform 0.3s; color: var(--text-muted); font-size: 1.2rem;">expand_more</span>
            </button>

            @if (isProfileMenuOpen()) {
              <!-- Backdrop -->
              <div class="profile-backdrop" (click)="isProfileMenuOpen.set(false)" style="position: fixed; inset: 0; z-index: 99;"></div>
              
              <!-- Dropdown Box -->
              <div class="profile-dropdown glass-card" style="position: absolute; right: 0; top: calc(100% + 10px); width: 280px; z-index: 100; padding: 8px; border-radius: 16px; display: flex; flex-direction: column; gap: 4px; box-shadow: 0 10px 30px rgba(0,0,0,0.15);">
                
                <!-- User Info Header -->
                <a routerLink="/dashboard/profile" class="dropdown-user-info dropdown-item-hover" (click)="isProfileMenuOpen.set(false)" style="display: flex; align-items: center; gap: 12px; padding: 12px; border-bottom: 1px solid var(--border-card); margin-bottom: 4px; text-decoration: none; color: var(--text-main); border-radius: 12px;">
                  <img [src]="authService.currentUser()?.avatarUrl || 'https://ui-avatars.com/api/?name=' + (authService.currentUser()?.fullName || 'U') + '&background=random'" alt="Avatar" class="user-avatar" style="width: 44px; height: 44px; border-radius: 50%;">
                  <div style="display: flex; flex-direction: column; overflow: hidden;">
                     <span style="font-weight: 600; white-space: nowrap; text-overflow: ellipsis; overflow: hidden; font-size: 0.95rem;">{{ authService.currentUser()?.fullName }}</span>
                     <span style="font-size: 0.8rem; color: var(--text-muted); white-space: nowrap; text-overflow: ellipsis; overflow: hidden;">{{ authService.currentUser()?.email }}</span>
                  </div>
                </a>

                <!-- Admin Panel Button -->
                @if (isAdmin()) {
                <a routerLink="/admin" class="dropdown-item dropdown-item-hover" (click)="isProfileMenuOpen.set(false)" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; text-decoration: none; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">admin_panel_settings</span>
                  <span>Administration</span>
                </a>
                }

                <!-- App mode switch -->
                <button (click)="cycleAppMode()" class="dropdown-item dropdown-item-hover" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; border: none; background: none; width: 100%; text-align: left; cursor: pointer; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">
                    {{ themeService.appMode() === 'light' ? 'dark_mode' : (themeService.appMode() === 'dark' ? 'contrast' : 'light_mode') }}
                  </span>
                  <span>
                    {{ themeService.appMode() === 'light' ? 'Mode Sombre' : (themeService.appMode() === 'dark' ? 'Mode OLED' : 'Mode Clair') }}
                  </span>
                </button>

                <!-- Language Selector -->
                <div class="dropdown-item-group" style="padding: 10px 12px; margin-top: 4px; border-top: 1px solid var(--border-card);">
                  <span style="font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600; color: var(--text-muted); margin-bottom: 10px; display: block;">Langue</span>
                  <div style="display: flex; gap: 8px;">
                    @for (lang of languages; track lang.code) {
                      <button (click)="setLanguage(lang.code)" class="lang-pill" [style.background]="t9n.currentLang() === lang.code ? 'rgba(37, 99, 235, 0.1)' : 'transparent'" [style.borderColor]="t9n.currentLang() === lang.code ? 'var(--primary-color)' : 'var(--border-card)'" [style.color]="t9n.currentLang() === lang.code ? 'var(--primary-color)' : 'var(--text-main)'" style="border: 1px solid; border-radius: 20px; padding: 6px 12px; font-size: 0.85rem; font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; flex: 1; justify-content: center;">
                        <img [src]="lang.flagUrl" alt="flag" style="width: 16px; height: 11px; object-fit: cover; border-radius: 2px;">
                        {{ lang.label }}
                      </button>
                    }
                  </div>
                </div>

                <!-- Logout -->
                <button (click)="onLogout()" class="dropdown-item dropdown-item-hover text-error" style="display: flex; align-items: center; gap: 12px; padding: 12px; border: none; background: none; width: 100%; text-align: left; cursor: pointer; color: #ef4444; border-top: 1px solid var(--border-card); margin-top: 4px; border-radius: 0 0 16px 16px; font-size: 0.9rem; font-weight: 500;">
                  <span class="material-symbols-outlined" style="font-size: 1.2rem;">logout</span>
                  <span>{{ t9n.t('nav.logout') || 'Déconnexion' }}</span>
                </button>

              </div>
            }
          </div>

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
export class MainLayoutComponent implements OnInit {
  readonly authService = inject(AuthService);
  readonly uiService = inject(UiService);
  readonly themeService = inject(ThemeService);
  private readonly router = inject(Router);
  t9n = inject(TranslationService);
  pwaService = inject(PwaService);

  readonly languages: { code: Language; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);
  isSidebarOpen = signal<boolean>(false);
  isProfileMenuOpen = signal<boolean>(false);

  ngOnInit() {
  }

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  setLanguage(lang: Language) {
    this.t9n.setLanguage(lang);
    this.isLangMenuOpen.set(false);
  }

  cycleAppMode() {
    if (this.themeService.appMode() === 'light') {
      this.themeService.setAppMode('dark');
    } else if (this.themeService.appMode() === 'dark') {
      this.themeService.setAppMode('oled');
    } else {
      this.themeService.setAppMode('light');
    }
  }

  isAdmin(): boolean {
    const user = this.authService.currentUser();
    return user?.roles?.includes('ROLE_ADMIN') || user?.roles?.includes('ROLE_SUPERADMIN') || false;
  }

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/login']);
    });
  }
}
