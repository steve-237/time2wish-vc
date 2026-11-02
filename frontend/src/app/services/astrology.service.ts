import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, of, catchError, map } from 'rxjs';
import { environment } from '../../environments/environment';
import { AstrologyInsight, ZodiacCompatibility } from '../models/astrology.model';

@Injectable({
  providedIn: 'root'
})
export class AstrologyService {
  private readonly http = inject(HttpClient);
  private readonly API_URL = environment.apiUrl + '/astrology';

  // User preference: toggle astrology insights on/off
  private readonly STORAGE_KEY = 'time2wish_show_astrology';
  readonly showAstrology = signal<boolean>(this.loadAstrologyPreference());

  toggleAstrology(enabled: boolean): void {
    this.showAstrology.set(enabled);
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(enabled));
  }

  private loadAstrologyPreference(): boolean {
    try {
      const saved = localStorage.getItem(this.STORAGE_KEY);
      return saved !== null ? JSON.parse(saved) : true;
    } catch {
      return true;
    }
  }

  getInsights(birthdate: string, lang: string = 'fr'): Observable<AstrologyInsight> {
    return this.http.get<AstrologyInsight>(`${this.API_URL}/insights?birthdate=${birthdate}&lang=${lang}`).pipe(
      catchError(() => of(this.computeLocalInsights(birthdate, lang)))
    );
  }

  getCompatibility(date1: string, date2: string, lang: string = 'fr'): Observable<ZodiacCompatibility> {
    return this.http.get<ZodiacCompatibility>(`${this.API_URL}/compatibility?date1=${date1}&date2=${date2}&lang=${lang}`).pipe(
      catchError(() => of(this.computeLocalCompatibility(date1, date2, lang)))
    );
  }

  computeLocalInsights(birthdate: string, lang: string = 'fr'): AstrologyInsight {
    const d = new Date(birthdate);
    const month = d.getMonth() + 1;
    const day = d.getDate();
    const year = d.getFullYear();

    let sign = 'Bélier';
    let emoji = '♈';
    let element = 'Feu';
    let planet = 'Mars';
    let range = '21 mars - 19 avril';
    let traits = ['Courageux', 'Pionnier', 'Énergique', 'Spontané'];
    let luckyNums = [9, 18, 27];
    let luckyDays = ['Mardi'];
    let luckyColors = ['Rouge', 'Corail'];
    let compatible = ['Lion', 'Sagittaire', 'Verseau', 'Gémeaux'];

    if ((month === 4 && day >= 20) || (month === 5 && day <= 20)) {
      sign = 'Taureau'; emoji = '♉'; element = 'Terre'; planet = 'Vénus'; range = '20 avril - 20 mai';
      traits = ['Persévérant', 'Loyal', 'Généreux', 'Pragmatique']; luckyNums = [6, 15, 24]; luckyDays = ['Vendredi']; luckyColors = ['Vert émeraude', 'Rose']; compatible = ['Vierge', 'Capricorne', 'Cancer', 'Poissons'];
    } else if ((month === 5 && day >= 21) || (month === 6 && day <= 20)) {
      sign = 'Gémeaux'; emoji = '♊'; element = 'Air'; planet = 'Mercure'; range = '21 mai - 20 juin';
      traits = ['Curieux', 'Éloquent', 'Vif d\'esprit', 'Adaptable']; luckyNums = [5, 14, 23]; luckyDays = ['Mercredi']; luckyColors = ['Jaune solaire', 'Bleu ciel']; compatible = ['Balance', 'Verseau', 'Bélier', 'Lion'];
    } else if ((month === 6 && day >= 21) || (month === 7 && day <= 22)) {
      sign = 'Cancer'; emoji = '♋'; element = 'Eau'; planet = 'Lune'; range = '21 juin - 22 juillet';
      traits = ['Protecteur', 'Intuitif', 'Sensible', 'Dévoué']; luckyNums = [2, 7, 11]; luckyDays = ['Lundi']; luckyColors = ['Blanc perle', 'Argent']; compatible = ['Scorpion', 'Poissons', 'Taureau', 'Vierge'];
    } else if ((month === 7 && day >= 23) || (month === 8 && day <= 22)) {
      sign = 'Lion'; emoji = '♌'; element = 'Feu'; planet = 'Soleil'; range = '23 juillet - 22 août';
      traits = ['Magnanime', 'Chaleureux', 'Rayonnant', 'Leader']; luckyNums = [1, 10, 19]; luckyDays = ['Dimanche']; luckyColors = ['Or', 'Ambre']; compatible = ['Bélier', 'Sagittaire', 'Balance', 'Gémeaux'];
    } else if ((month === 8 && day >= 23) || (month === 9 && day <= 22)) {
      sign = 'Vierge'; emoji = '♍'; element = 'Terre'; planet = 'Mercure'; range = '23 août - 22 septembre';
      traits = ['Méthodique', 'Bienveillant', 'Sensible', 'Perspicace']; luckyNums = [5, 14, 32]; luckyDays = ['Mercredi']; luckyColors = ['Bleu marine', 'Beige']; compatible = ['Taureau', 'Capricorne', 'Cancer', 'Scorpion'];
    } else if ((month === 9 && day >= 23) || (month === 10 && day <= 22)) {
      sign = 'Balance'; emoji = '♎'; element = 'Air'; planet = 'Vénus'; range = '23 septembre - 22 octobre';
      traits = ['Harmonieux', 'Juste', 'Diplomate', 'Raffiné']; luckyNums = [6, 15, 24]; luckyDays = ['Vendredi']; luckyColors = ['Bleu pastel', 'Rose pêche']; compatible = ['Gémeaux', 'Verseau', 'Lion', 'Sagittaire'];
    } else if ((month === 10 && day >= 23) || (month === 11 && day <= 21)) {
      sign = 'Scorpion'; emoji = '♏'; element = 'Eau'; planet = 'Pluton'; range = '23 octobre - 21 novembre';
      traits = ['Passionné', 'Magnétique', 'Résolu', 'Loyal']; luckyNums = [8, 17, 26]; luckyDays = ['Mardi']; luckyColors = ['Pourpre', 'Bordeaux']; compatible = ['Cancer', 'Poissons', 'Vierge', 'Capricorne'];
    } else if ((month === 11 && day >= 22) || (month === 12 && day <= 21)) {
      sign = 'Sagittaire'; emoji = '♐'; element = 'Feu'; planet = 'Jupiter'; range = '22 novembre - 21 décembre';
      traits = ['Optimiste', 'Visionnaire', 'Aventurier', 'Généreux']; luckyNums = [3, 12, 21]; luckyDays = ['Jeudi']; luckyColors = ['Violet royal', 'Indigo']; compatible = ['Bélier', 'Lion', 'Balance', 'Verseau'];
    } else if ((month === 12 && day >= 22) || (month === 1 && day <= 19)) {
      sign = 'Capricorne'; emoji = '♑'; element = 'Terre'; planet = 'Saturne'; range = '22 décembre - 19 janvier';
      traits = ['Ambitieux', 'Sage', 'Discipliné', 'Fiable']; luckyNums = [4, 13, 22]; luckyDays = ['Samedi']; luckyColors = ['Gris ardoise', 'Marron chaud']; compatible = ['Taureau', 'Vierge', 'Scorpion', 'Poissons'];
    } else if ((month === 1 && day >= 20) || (month === 2 && day <= 18)) {
      sign = 'Verseau'; emoji = '♒'; element = 'Air'; planet = 'Uranus'; range = '20 janvier - 18 février';
      traits = ['Innovant', 'Humaniste', 'Idéaliste', 'Fraternel']; luckyNums = [4, 7, 11]; luckyDays = ['Samedi']; luckyColors = ['Bleu électrique', 'Turquoise']; compatible = ['Gémeaux', 'Balance', 'Bélier', 'Sagittaire'];
    } else if ((month === 2 && day >= 19) || (month === 3 && day <= 20)) {
      sign = 'Poissons'; emoji = '♓'; element = 'Eau'; planet = 'Neptune'; range = '19 février - 20 mars';
      traits = ['Empathique', 'Créatif', 'Rêveur', 'Généreux']; luckyNums = [3, 7, 12]; luckyDays = ['Jeudi']; luckyColors = ['Vert d\'eau', 'Bleu marine']; compatible = ['Cancer', 'Scorpion', 'Taureau', 'Capricorne'];
    }

    const chineseAnimals = [
      { name: 'Rat', emoji: '🐀' }, { name: 'Bœuf', emoji: '🐂' }, { name: 'Tigre', emoji: '🐅' },
      { name: 'Lapin', emoji: '🐇' }, { name: 'Dragon', emoji: '🐉' }, { name: 'Serpent', emoji: '🐍' },
      { name: 'Cheval', emoji: '🐎' }, { name: 'Chèvre', emoji: '🐐' }, { name: 'Singe', emoji: '🐒' },
      { name: 'Coq', emoji: '🐓' }, { name: 'Chien', emoji: '🐕' }, { name: 'Cochon', emoji: '🐖' }
    ];
    const cIndex = (year - 4) % 12;
    const cAnimal = chineseAnimals[cIndex >= 0 ? cIndex : cIndex + 12];

    const lastDigit = Math.abs(year) % 10;
    let cElement = 'Terre';
    if (lastDigit === 0 || lastDigit === 1) cElement = 'Métal';
    else if (lastDigit === 2 || lastDigit === 3) cElement = 'Eau';
    else if (lastDigit === 4 || lastDigit === 5) cElement = 'Bois';
    else if (lastDigit === 6 || lastDigit === 7) cElement = 'Feu';

    return {
      birthdate,
      westernSign: sign,
      westernSymbol: emoji,
      westernEmoji: emoji,
      westernDateRange: range,
      element,
      modality: 'Fixe',
      rulingPlanet: planet,
      personalityTraits: traits,
      luckyNumbers: luckyNums,
      luckyDays,
      luckyColors,
      compatibleSigns: compatible,
      chineseAnimal: cAnimal.name,
      chineseSymbol: cAnimal.emoji,
      chineseEmoji: cAnimal.emoji,
      chineseElement: cElement,
      polarity: year % 2 === 0 ? 'Yang' : 'Yin',
      celebrationHoroscope: `Sous les auspices bienveillants de ${planet} et la constellation du ${sign}, cette nouvelle année personnelle s'ouvre sous le signe de l'expansion et de la réussite. Votre énergie de ${cAnimal.name} alliée à la noblesse de votre élément ${element} attire à vous des opportunités inspirantes et de vibrantes célébrations !`,
      dailyAffirmation: 'Je rayonne de confiance, d\'enthousiasme et d\'une force créatrice inaltérable.'
    };
  }

  computeLocalCompatibility(date1: string, date2: string, lang: string = 'fr'): ZodiacCompatibility {
    const s1 = this.computeLocalInsights(date1, lang);
    const s2 = this.computeLocalInsights(date2, lang);

    let score = 80;
    if (s1.westernSign === s2.westernSign) score = 88;
    else if (s1.element === s2.element) score = 92;
    else if ((s1.element === 'Feu' && s2.element === 'Air') || (s1.element === 'Air' && s2.element === 'Feu')) score = 95;
    else if ((s1.element === 'Terre' && s2.element === 'Eau') || (s1.element === 'Eau' && s2.element === 'Terre')) score = 94;

    return {
      birthdate1: date1,
      birthdate2: date2,
      sign1: s1.westernSign,
      sign1Emoji: s1.westernEmoji,
      sign2: s2.westernSign,
      sign2Emoji: s2.westernEmoji,
      compatibilityScore: score,
      elementHarmony: `Complicité Vibrante (${s1.element} + ${s2.element})`,
      synergyDescription: `${s1.westernSign} et ${s2.westernSign} partagent une alchimie naturelle qui démultiplie l'inspiration et les projets communs !`,
      tipForHarmony: 'Valorisez vos talents respectifs et organisez des célébrations régulières pour nourrir votre lien cosmique !'
    };
  }
}
