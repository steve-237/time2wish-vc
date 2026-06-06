import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslationService, Language } from './services/translation.service';
import { AuthService } from './services/auth.service';
import { NotificationPanelComponent } from './components/notification-panel/notification-panel.component';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';
import { PwaService } from './services/pwa.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, NotificationPanelComponent, ToastContainerComponent],
  templateUrl: './app.html',
  styleUrl: './app.scss'
})
export class App implements OnInit {
  authService = inject(AuthService);
  router = inject(Router);
  t9n = inject(TranslationService);
  pwaService = inject(PwaService);
  appMode = signal<'light' | 'dark' | 'oled'>('light');
  colorTheme = signal<string>('theme-ocean');

  readonly languages: { code: Language; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  ngOnInit() {
    // Load app mode preference
    const storedMode = localStorage.getItem('t2w_app_mode');
    const legacyDark = localStorage.getItem('t2w_dark_mode') === 'true';
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    let modeToApply: 'light' | 'dark' | 'oled' = 'light';
    
    if (storedMode === 'dark' || storedMode === 'oled') {
      modeToApply = storedMode;
    } else if (legacyDark || (!storedMode && prefersDark)) {
      modeToApply = 'dark';
    }

    this.appMode.set(modeToApply);
    if (modeToApply === 'dark') document.body.classList.add('dark-theme');
    if (modeToApply === 'oled') document.body.classList.add('oled-theme');

    // Load color theme
    const storedColorTheme = localStorage.getItem('t2w_color_theme');
    if (storedColorTheme) {
      this.colorTheme.set(storedColorTheme);
      document.body.classList.add(storedColorTheme);
    } else {
      document.body.classList.add('theme-ocean');
    }
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

  setColorTheme(theme: string) {
    // Remove old theme class
    document.body.classList.remove(this.colorTheme());
    // Add new theme class
    document.body.classList.add(theme);
    this.colorTheme.set(theme);
    localStorage.setItem('t2w_color_theme', theme);
  }

  setLanguage(lang: Language) {
    this.t9n.setLanguage(lang);
    this.isLangMenuOpen.set(false);
  }

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/login']);
    });
  }
}

