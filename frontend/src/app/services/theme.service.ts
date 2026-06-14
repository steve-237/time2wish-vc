import { Injectable, inject, signal, effect } from '@angular/core';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private readonly authService = inject(AuthService);
  
  readonly appMode = signal<'light' | 'dark' | 'oled'>('light');
  readonly colorTheme = signal<string>('theme-ocean');

  constructor() {
    // Whenever the logged-in user changes, reload their specific theme
    effect(() => {
      const user = this.authService.currentUser();
      this.loadTheme(user?.id);
    }, { allowSignalWrites: true });
  }

  private loadTheme(userId?: number) {
    let storedMode: string | null = null;
    let storedColor: string | null = null;

    if (userId) {
      storedMode = localStorage.getItem(`t2w_app_mode_${userId}`);
      storedColor = localStorage.getItem(`t2w_color_theme_${userId}`);
    } else {
      storedMode = localStorage.getItem('t2w_app_mode');
      storedColor = localStorage.getItem('t2w_color_theme');
    }

    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    let mode: 'light' | 'dark' | 'oled' = 'light';
    if (storedMode === 'dark' || storedMode === 'oled') {
      mode = storedMode;
    } else if (!storedMode && prefersDark) {
      mode = 'dark';
    }

    const color = storedColor || 'theme-ocean';

    this.appMode.set(mode);
    this.colorTheme.set(color);
    
    this.applyThemeClasses(mode, color);
  }

  setAppMode(mode: 'light' | 'dark' | 'oled') {
    const user = this.authService.currentUser();
    const modeKey = user?.id ? `t2w_app_mode_${user.id}` : 't2w_app_mode';
    localStorage.setItem(modeKey, mode);
    this.appMode.set(mode);
    this.applyThemeClasses(mode, this.colorTheme());
  }

  setColorTheme(themeId: string) {
    const user = this.authService.currentUser();
    const colorKey = user?.id ? `t2w_color_theme_${user.id}` : 't2w_color_theme';
    localStorage.setItem(colorKey, themeId);
    this.colorTheme.set(themeId);
    this.applyThemeClasses(this.appMode(), themeId);
  }

  private applyThemeClasses(mode: 'light' | 'dark' | 'oled', colorTheme: string) {
    document.body.classList.remove('dark-theme', 'oled-theme');
    if (mode === 'dark') document.body.classList.add('dark-theme');
    if (mode === 'oled') document.body.classList.add('oled-theme');

    // Remove all existing color themes
    document.body.classList.forEach(className => {
      if (className.startsWith('theme-')) {
        document.body.classList.remove(className);
      }
    });
    
    document.body.classList.add(colorTheme);
  }
}
