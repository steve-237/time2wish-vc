import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export type Language = 'fr' | 'en' | 'de';

@Injectable({ providedIn: 'root' })
export class TranslationService {
  private http: HttpClient;

  /** Currently active language */
  readonly currentLang = signal<Language>('en');

  /** Loaded translations dictionary */
  private translations = signal<Record<string, unknown>>({});

  /** Flag: true once the first load has completed */
  readonly isLoaded = signal<boolean>(false);

  constructor(http: HttpClient) {
    this.http = http;
    // Restaurer la langue du localStorage ou utiliser la langue du système
    const savedLang = localStorage.getItem('t2w_lang') as Language;
    const browserLang = navigator.language.substring(0, 2).toLowerCase();
    const detected = savedLang || (['fr', 'en', 'de'].includes(browserLang) ? browserLang : 'en') as Language;
    
    this.currentLang.set(detected);
    this.loadLanguage(detected);
  }

  /** Switches language and re-loads the dictionary */
  setLanguage(lang: Language): void {
    this.currentLang.set(lang);
    localStorage.setItem('t2w_lang', lang);
    this.loadLanguage(lang);
  }

  /**
   * Translates a dot-separated key, e.g. 'dashboard.title'.
   * Supports simple %s / %d substitution.
   */
  t(key: string, ...args: (string | number)[]): string {
    const keys = key.split('.');
    let current: unknown = this.translations();

    for (const k of keys) {
      if (current && typeof current === 'object' && k in (current as Record<string, unknown>)) {
        current = (current as Record<string, unknown>)[k];
      } else {
        return ''; // fallback to empty string so template '||' operator works
      }
    }

    if (typeof current !== 'string') return '';

    // Simple printf-style substitution for %s and %d
    let result = current;
    args.forEach(arg => {
      result = result.replace(/%[sd]/, String(arg));
    });
    return result;
  }

  /**
   * Returns the months array for the current language.
   */
  getMonths(): string[] {
    const months = (this.translations() as Record<string, unknown>)['dashboard'];
    if (months && typeof months === 'object' && 'months' in months) {
      const arr = (months as Record<string, unknown>)['months'];
      if (Array.isArray(arr)) return arr as string[];
    }
    return [];
  }

  private loadLanguage(lang: Language): void {
    this.isLoaded.set(false);
    this.http.get<Record<string, unknown>>(`/assets/i18n/${lang}.json`).subscribe({
      next: (data) => {
        this.currentLang.set(lang);
        this.translations.set(data);
        this.isLoaded.set(true);
      },
      error: (err) => {
        console.warn(`[TranslationService] Failed to load '${lang}' translations. Using template fallbacks.`);
        this.currentLang.set(lang);
        this.translations.set({});
        this.isLoaded.set(true);
      }
    });
  }
}
