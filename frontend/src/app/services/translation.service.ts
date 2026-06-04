import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export type Language = 'fr' | 'en' | 'de';

@Injectable({ providedIn: 'root' })
export class TranslationService {
  private http: HttpClient;

  /** Currently active language */
  readonly currentLang = signal<Language>('fr');

  /** Loaded translations dictionary */
  private translations = signal<Record<string, unknown>>({});

  /** Flag: true once the first load has completed */
  readonly isLoaded = signal<boolean>(false);

  constructor(http: HttpClient) {
    this.http = http;
    const saved = (localStorage.getItem('t2w_lang') as Language) || 'fr';
    this.loadLanguage(saved);
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
        return key; // fallback to key itself
      }
    }

    if (typeof current !== 'string') return key;

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
        console.error(`[TranslationService] Failed to load '${lang}' translations:`, err);
        // Fallback: try French
        if (lang !== 'fr') {
          this.loadLanguage('fr');
        } else {
          this.isLoaded.set(true);
        }
      }
    });
  }
}
