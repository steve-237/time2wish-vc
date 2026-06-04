import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TranslationService } from './translation.service';
import { HttpClient } from '@angular/common/http';
import { of, throwError } from 'rxjs';

// ─── Données de traduction factices ────────────────────────────────────────
const mockFrTranslations = {
  nav: { dashboard: 'Tableau de bord', logout: 'Déconnexion' },
  dashboard: {
    title: 'Mon Tableau de Bord 🚀',
    stat_total: 'Total Anniversaires',
    months: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
             'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
  },
  countdown: {
    today: '🎂 Aujourd\'hui !',
    tomorrow: '⚡ Demain !',
    days: '📅 %d jours',
  },
};

const mockEnTranslations = {
  nav: { dashboard: 'Dashboard', logout: 'Logout' },
  dashboard: {
    title: 'My Dashboard 🚀',
    stat_total: 'Total Birthdays',
    months: ['January', 'February', 'March', 'April', 'May', 'June',
             'July', 'August', 'September', 'October', 'November', 'December'],
  },
  countdown: {
    today: '🎂 Today!',
    tomorrow: '⚡ Tomorrow!',
    days: '📅 %d days',
  },
};

// ─── Mock de HttpClient ──────────────────────────────────────────────────────
function createMockHttp(data: Record<string, unknown>) {
  return { get: vi.fn().mockReturnValue(of(data)) } as unknown as HttpClient;
}

describe('TranslationService', () => {
  let service: TranslationService;
  let httpMock: { get: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    // Simule localStorage
    vi.spyOn(Storage.prototype, 'getItem').mockReturnValue(null);
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {});

    httpMock = { get: vi.fn().mockReturnValue(of(mockFrTranslations)) };
    service = new TranslationService(httpMock as unknown as HttpClient);
  });

  // ─── Initialisation ────────────────────────────────────────────────────

  it('devrait charger le français par défaut au démarrage', () => {
    expect(httpMock.get).toHaveBeenCalledWith('/assets/i18n/fr.json');
  });

  it('devrait indiquer isLoaded = true après le chargement réussi', () => {
    expect(service.isLoaded()).toBe(true);
  });

  it('devrait définir currentLang = "fr" par défaut', () => {
    expect(service.currentLang()).toBe('fr');
  });

  // ─── t() : résolution de clés ──────────────────────────────────────────

  it('t() devrait résoudre une clé simple (un niveau)', () => {
    expect(service.t('dashboard.title')).toBe('Mon Tableau de Bord 🚀');
  });

  it('t() devrait résoudre une clé imbriquée (deux niveaux)', () => {
    expect(service.t('nav.dashboard')).toBe('Tableau de bord');
  });

  it('t() devrait retourner la clé elle-même si absente', () => {
    expect(service.t('clé.inexistante')).toBe('clé.inexistante');
  });

  it('t() devrait remplacer %d par un argument numérique', () => {
    const result = service.t('countdown.days', 5);
    expect(result).toBe('📅 5 jours');
  });

  it('t() devrait remplacer %s par une chaîne de caractères', () => {
    // Ajoute une clé avec %s pour tester
    const testTranslations = {
      ...mockFrTranslations,
      dashboard: {
        ...mockFrTranslations.dashboard,
        wish_message: 'Joyeux anniversaire %s !',
      },
    };
    (httpMock.get as ReturnType<typeof vi.fn>).mockReturnValue(of(testTranslations));
    service = new TranslationService(httpMock as unknown as HttpClient);

    const result = service.t('dashboard.wish_message', 'Alice');
    expect(result).toBe('Joyeux anniversaire Alice !');
  });

  // ─── getMonths() ────────────────────────────────────────────────────────

  it('getMonths() devrait retourner exactement 12 mois', () => {
    const months = service.getMonths();
    expect(months).toHaveLength(12);
  });

  it('getMonths() devrait commencer par Janvier en français', () => {
    const months = service.getMonths();
    expect(months[0]).toBe('Janvier');
  });

  it('getMonths() devrait retourner [] si pas de traductions chargées', () => {
    (httpMock.get as ReturnType<typeof vi.fn>).mockReturnValue(of({}));
    service = new TranslationService(httpMock as unknown as HttpClient);
    expect(service.getMonths()).toEqual([]);
  });

  // ─── setLanguage() ──────────────────────────────────────────────────────

  it('setLanguage("en") devrait mettre à jour currentLang et charger l\'anglais', () => {
    (httpMock.get as ReturnType<typeof vi.fn>).mockReturnValue(of(mockEnTranslations));
    service.setLanguage('en');

    expect(service.currentLang()).toBe('en');
    expect(httpMock.get).toHaveBeenCalledWith('/assets/i18n/en.json');
  });

  it('setLanguage() devrait persister le choix dans localStorage', () => {
    (httpMock.get as ReturnType<typeof vi.fn>).mockReturnValue(of(mockEnTranslations));
    service.setLanguage('en');

    expect(localStorage.setItem).toHaveBeenCalledWith('t2w_lang', 'en');
  });

  // ─── Fallback d'erreur ─────────────────────────────────────────────────

  it('devrait se rabattre sur le français si le chargement d\'une langue échoue', () => {
    // Premier appel (de) échoue, second (fr) réussit
    (httpMock.get as ReturnType<typeof vi.fn>)
      .mockReturnValueOnce(throwError(() => new Error('404')))
      .mockReturnValueOnce(of(mockFrTranslations));

    service.setLanguage('de');

    // Le fallback déclenche un chargement en français
    expect(httpMock.get).toHaveBeenCalledWith('/assets/i18n/fr.json');
  });
});
