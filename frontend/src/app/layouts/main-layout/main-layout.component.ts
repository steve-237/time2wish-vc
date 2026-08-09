import { Component, signal, inject, OnInit, HostListener, ElementRef } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslationService, Language } from '../../services/translation.service';
import { AuthService } from '../../services/auth.service';
import { NotificationPanelComponent } from '../../components/notification-panel/notification-panel.component';
import { PwaService } from '../../services/pwa.service';
import { PricingComponent } from '../../pages/pricing/pricing.component';
import { FeedbackModalComponent } from '../../components/feedback-modal/feedback-modal.component';
import { MobileNavComponent } from '../../components/mobile-nav/mobile-nav.component';
import { UiService } from '../../services/ui.service';
import { ThemeService } from '../../services/theme.service';
import { ToastService } from '../../services/toast.service';
import { MessagingService } from '../../services/messaging.service';
import { AnnouncementService } from '../../services/announcement.service';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, NotificationPanelComponent, PricingComponent, FeedbackModalComponent, MobileNavComponent],
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
          <!-- Messaging Button -->
          <a routerLink="/dashboard/messaging" class="messaging-nav-btn" [title]="t9n.t('nav.messaging') || 'Messagerie'">
            <span class="material-symbols-outlined">chat</span>
            <span class="hide-mobile">{{ t9n.t('nav.messaging') || 'Messages' }}</span>
            @if (messagingService.unreadCount() > 0) {
              <span class="unread-badge">{{ messagingService.unreadCount() }}</span>
            }
          </a>

          <!-- Pricing/Plans Button -->
          <button (click)="uiService.isPricingModalOpen.set(true)" class="PRO-nav-btn" [title]="t9n.t('nav.plans') || 'Forfaits'">
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

          <!-- WishCoins Display -->
          <button class="coins-display flex-center" (click)="uiService.isPricingModalOpen.set(true)" style="gap: 4px; padding: 6px 12px; background: rgba(245, 158, 11, 0.15); border-radius: 20px; border: 1px solid rgba(245, 158, 11, 0.3); color: #f59e0b; font-weight: 700; font-size: 0.95rem; margin: 0 4px; cursor: pointer; transition: all 0.2s ease;" title="Vos WishCoins - Cliquez pour recharger" onmouseover="this.style.background='rgba(245, 158, 11, 0.25)'" onmouseout="this.style.background='rgba(245, 158, 11, 0.15)'">
            <span class="material-symbols-outlined" style="font-size: 18px; color: #f59e0b;">generating_tokens</span>
            <span>{{ authService.currentUser()?.coins || 0 }}</span>
          </button>

          <!-- Profile Dropdown Menu Container -->
          <div class="profile-menu-container" style="position: relative;">
            <button class="profile-toggle-btn flex-center" (click)="isProfileMenuOpen.set(!isProfileMenuOpen())" style="background: none; border: none; cursor: pointer; padding: 4px; border-radius: 30px; gap: 4px; transition: background 0.2s;">
              <img [src]="authService.currentUser()?.avatarUrl || 'https://ui-avatars.com/api/?name=' + (authService.currentUser()?.fullName || 'U') + '&background=random'" alt="Avatar" class="user-avatar" style="width: 36px; height: 36px; border-radius: 50%; border: 2px solid var(--border-card);">
              <span class="material-symbols-outlined profile-chevron" [style.transform]="isProfileMenuOpen() ? 'rotate(180deg)' : 'none'" style="transition: transform 0.3s; color: var(--text-muted); font-size: 1.2rem;">expand_more</span>
            </button>

            @if (isProfileMenuOpen()) {
              <!-- Removed backdrop in favor of HostListener -->
              
              <!-- Dropdown Box -->
              <div class="profile-dropdown" style="position: absolute; right: 0; top: calc(100% + 10px); width: 280px; z-index: 100; padding: 8px; border-radius: 16px; display: flex; flex-direction: column; gap: 4px; box-shadow: 0 10px 40px rgba(0,0,0,0.4); background: var(--bg-dropdown); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); border: 1px solid var(--border-card);">
                
                <a routerLink="/dashboard/profile" class="dropdown-user-info dropdown-item-hover" (click)="isProfileMenuOpen.set(false)" style="display: flex; align-items: center; gap: 12px; padding: 12px; border-bottom: 1px solid var(--border-card); margin-bottom: 4px; text-decoration: none; color: var(--text-main); border-radius: 12px;">
                  <img [src]="authService.currentUser()?.avatarUrl || 'https://ui-avatars.com/api/?name=' + (authService.currentUser()?.fullName || 'U') + '&background=random'" alt="Avatar" class="user-avatar" style="width: 44px; height: 44px; border-radius: 50%;">
                  <div style="display: flex; flex-direction: column; overflow: hidden; width: 100%;">
                     <span style="font-weight: 600; white-space: nowrap; text-overflow: ellipsis; overflow: hidden; font-size: 0.95rem;">{{ authService.currentUser()?.fullName }}</span>
                     <span style="font-size: 0.8rem; color: var(--text-muted); white-space: nowrap; text-overflow: ellipsis; overflow: hidden;">{{ authService.currentUser()?.email }}</span>
                     @if (authService.currentUser()?.badges?.length) {
                       <div style="display: flex; gap: 4px; margin-top: 4px;">
                         @for (badge of authService.currentUser()?.badges; track badge) {
                           <span [title]="badge" style="font-size: 1rem; cursor: help;">{{ getBadgeEmoji(badge) }}</span>
                         }
                       </div>
                     }
                  </div>
                </a>

                <!-- Admin Panel Button -->
                @if (isAdmin()) {
                <a routerLink="/admin" class="dropdown-item dropdown-item-hover" (click)="isProfileMenuOpen.set(false)" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; text-decoration: none; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">admin_panel_settings</span>
                  <span>Administration</span>
                </a>
                }

                <!-- Support Button -->
                <a routerLink="/dashboard/support" class="dropdown-item dropdown-item-hover" (click)="isProfileMenuOpen.set(false)" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; text-decoration: none; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">support_agent</span>
                  <span>Support & Contact</span>
                </a>

                <!-- Feedback Button -->
                <button (click)="isFeedbackModalOpen.set(true); isProfileMenuOpen.set(false)" class="dropdown-item dropdown-item-hover" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; border: none; background: none; width: 100%; text-align: left; cursor: pointer; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">rate_review</span>
                  <span>Donner mon avis</span>
                </button>

                <!-- App mode switch -->
                <button (click)="cycleAppMode()" class="dropdown-item dropdown-item-hover" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; border: none; background: none; width: 100%; text-align: left; cursor: pointer; color: var(--text-main); border-radius: 10px; font-size: 0.9rem;">
                  <span class="material-symbols-outlined" style="color: var(--text-muted); font-size: 1.2rem;">
                    {{ themeService.appMode() === 'light' ? 'dark_mode' : (themeService.appMode() === 'dark' ? 'contrast' : 'light_mode') }}
                  </span>
                  <span>
                    {{ themeService.appMode() === 'light' ? 'Mode Sombre' : (themeService.appMode() === 'dark' ? 'Mode OLED' : 'Mode Clair') }}
                  </span>
                  @if (themeService.appMode() === 'dark' && authService.currentUser()?.plan === 'BASIC') {
                    <span class="material-symbols-outlined" style="font-size: 1rem; color: #fbbf24; margin-left: auto;">lock</span>
                  }
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
      @if (activeAnnouncement()) {
        <div class="announcement-banner" [ngClass]="'banner-' + activeAnnouncement()?.type?.toLowerCase()">
          <div class="banner-content">
            <span class="material-symbols-outlined icon">
              {{ activeAnnouncement()?.type === 'WARNING' ? 'warning' : (activeAnnouncement()?.type === 'SUCCESS' ? 'check_circle' : 'info') }}
            </span>
            <div class="text">
              <strong>{{ activeAnnouncement()?.title }}</strong> - {{ activeAnnouncement()?.message }}
            </div>
            <button class="icon-btn close-btn" (click)="activeAnnouncement.set(null)">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>
        </div>
      }

      <router-outlet></router-outlet>
      @if (uiService.isPricingModalOpen()) {
        <app-pricing (close)="uiService.isPricingModalOpen.set(false)"></app-pricing>
      }
      @if (isFeedbackModalOpen()) {
        <app-feedback-modal (close)="isFeedbackModalOpen.set(false)"></app-feedback-modal>
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

    <!-- Mobile Navigation Bar -->
    <app-mobile-nav></app-mobile-nav>
  `,
  styles: [`
    .announcement-banner {
      width: 100%;
      padding: 12px 24px;
      margin-bottom: 16px;
      border-radius: 8px;
      font-size: 0.95rem;
    }
    .banner-content {
      display: flex;
      align-items: center;
      gap: 12px;
      max-width: 1200px;
      margin: 0 auto;
    }
    .banner-content .text {
      flex: 1;
    }
    .banner-info { background: rgba(59, 130, 246, 0.1); color: #3b82f6; border: 1px solid rgba(59, 130, 246, 0.2); }
    .banner-warning { background: rgba(245, 158, 11, 0.1); color: #f59e0b; border: 1px solid rgba(245, 158, 11, 0.2); }
    .banner-success { background: rgba(16, 185, 129, 0.1); color: #10b981; border: 1px solid rgba(16, 185, 129, 0.2); }
    .close-btn { color: inherit; opacity: 0.7; }
    .close-btn:hover { opacity: 1; }
  `]
})
export class MainLayoutComponent implements OnInit {
  readonly authService = inject(AuthService);
  readonly uiService = inject(UiService);
  readonly themeService = inject(ThemeService);
  private readonly router = inject(Router);
  t9n = inject(TranslationService);
  pwaService = inject(PwaService);
  messagingService = inject(MessagingService);
  private announcementService = inject(AnnouncementService);
  private readonly elementRef = inject(ElementRef);

  readonly languages: { code: Language; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);
  isSidebarOpen = signal<boolean>(false);
  isProfileMenuOpen = signal<boolean>(false);
  isFeedbackModalOpen = signal<boolean>(false);
  activeAnnouncement = signal<any>(null);

  getBadgeEmoji(badgeName: string): string {
    const badges = [
      { name: 'VIP', icon: '🌟' },
      { name: 'Donateur', icon: '💎' },
      { name: 'Créatif', icon: '🎨' },
      { name: 'Early Bird', icon: '🐣' },
      { name: 'Ambassadeur', icon: '📣' }
    ];
    return badges.find(b => b.name === badgeName)?.icon || '🏅';
  }

  ngOnInit() {
    if (this.authService.isAuthenticated()) {
      this.messagingService.getUnreadCount().subscribe();
      
      this.announcementService.getActiveAnnouncement().subscribe({
        next: (ann) => {
          if (ann) this.activeAnnouncement.set(ann);
        }
      });
    }
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: Event) {
    // Close profile menu if click is outside the profile menu container
    const profileContainer = this.elementRef.nativeElement.querySelector('.profile-menu-container');
    if (this.isProfileMenuOpen() && profileContainer && !profileContainer.contains(event.target as Node)) {
      this.isProfileMenuOpen.set(false);
    }
  }

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  setLanguage(lang: Language) {
    this.t9n.setLanguage(lang);
    this.isLangMenuOpen.set(false);
  }

  toastService = inject(ToastService);

  cycleAppMode() {
    if (this.themeService.appMode() === 'light') {
      this.themeService.setAppMode('dark');
    } else if (this.themeService.appMode() === 'dark') {
      const userPlan = this.authService.currentUser()?.plan || 'BASIC';
      if (userPlan === 'BASIC') {
        this.toastService.info("Le thème OLED nécessite le forfait PLUS.");
        this.uiService.isPricingModalOpen.set(true);
        this.themeService.setAppMode('light'); // cycle back to light
      } else {
        this.themeService.setAppMode('oled');
      }
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
