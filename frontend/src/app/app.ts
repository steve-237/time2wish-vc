import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from './services/auth.service';
import { TranslationService, Language } from './services/translation.service';
import { NotificationPanelComponent } from './components/notification-panel/notification-panel.component';
import { ToastContainerComponent } from './components/toast-container/toast-container.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, RouterLink, CommonModule, NotificationPanelComponent, ToastContainerComponent],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  authService = inject(AuthService);
  router = inject(Router);
  t9n = inject(TranslationService);
  
  isDarkMode = signal<boolean>(false);

  readonly languages: { code: Language; label: string; flag: string }[] = [
    { code: 'fr', label: 'FR', flag: '🇫🇷' },
    { code: 'en', label: 'EN', flag: '🇬🇧' },
    { code: 'de', label: 'DE', flag: '🇩🇪' },
  ];

  ngOnInit() {
    // Load dark mode preference
    const storedTheme = localStorage.getItem('t2w_theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    if (storedTheme === 'dark' || (!storedTheme && prefersDark)) {
      this.isDarkMode.set(true);
      document.body.classList.add('dark-theme');
    }
  }

  toggleDarkMode() {
    this.isDarkMode.update(dark => !dark);
    if (this.isDarkMode()) {
      document.body.classList.add('dark-theme');
      localStorage.setItem('t2w_theme', 'dark');
    } else {
      document.body.classList.remove('dark-theme');
      localStorage.setItem('t2w_theme', 'light');
    }
  }

  setLanguage(lang: Language) {
    this.t9n.setLanguage(lang);
  }

  onLogout() {
    this.authService.logout().subscribe(() => {
      this.router.navigate(['/login']);
    });
  }
}

