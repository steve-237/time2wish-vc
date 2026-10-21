import { Component, signal, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, Router, ActivatedRoute } from '@angular/router';
import { TranslationService, Language } from '../../services/translation.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './landing.component.html',
  styleUrl: './landing.component.scss'
})
export class LandingComponent implements OnInit {
  readonly t9n = inject(TranslationService);
  readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  readonly languages: { code: Language; label: string; flagUrl: string }[] = [
    { code: 'fr', label: 'FR', flagUrl: 'https://flagcdn.com/w40/fr.png' },
    { code: 'en', label: 'EN', flagUrl: 'https://flagcdn.com/w40/gb.png' },
    { code: 'de', label: 'DE', flagUrl: 'https://flagcdn.com/w40/de.png' },
  ];

  isLangMenuOpen = signal<boolean>(false);
  isMobileMenuOpen = signal<boolean>(false);

  // Active AI Demo preview tab
  activeAiTone = signal<'warm' | 'funny' | 'poetic'>('warm');

  readonly aiWishSamples = {
    warm: "Joyeux anniversaire Sophie ! Que cette nouvelle année t'apporte autant de joie, de rires et de succès que tu en répands autour de toi. Merci pour ta précieuse présence dans ma vie. 🎂✨",
    funny: "Joyeux anniversaire Sophie ! Ne t'inquiète pas pour les bougies qui augmentent, c'est juste que ton gâteau devient de plus en plus spectaculaire ! Profite à fond de ta journée ! 🥳🎈",
    poetic: "Comme les étoiles qui éclairent la nuit, que ce jour d'anniversaire illumine ton chemin pour l'année à venir. Que chaque instant soit une mélodie de bonheur. Bel anniversaire Sophie. 🌟💫"
  };

  ngOnInit(): void {
    // If the visitor is already authenticated and lands on the root '/', redirect to their dashboard
    // unless they explicitly arrived at /welcome
    const currentUrl = this.router.url;
    if (this.authService.isAuthenticated() && (currentUrl === '/' || currentUrl === '')) {
      this.router.navigate(['/dashboard']);
    }
  }

  getActiveFlagUrl(): string {
    return this.languages.find(l => l.code === this.t9n.currentLang())?.flagUrl || 'https://flagcdn.com/w40/fr.png';
  }

  setLanguage(lang: Language): void {
    this.t9n.setLanguage(lang);
    this.isLangMenuOpen.set(false);
  }

  scrollToSection(sectionId: string): void {
    const el = document.getElementById(sectionId);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth' });
      this.isMobileMenuOpen.set(false);
    }
  }
}
