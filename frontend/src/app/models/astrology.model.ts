export interface AstrologyInsight {
  birthdate: string;
  westernSign: string;
  westernSymbol: string;
  westernEmoji: string;
  westernDateRange: string;
  element: string;
  modality: string;
  rulingPlanet: string;
  personalityTraits: string[];
  luckyNumbers: number[];
  luckyDays: string[];
  luckyColors: string[];
  compatibleSigns: string[];
  chineseAnimal: string;
  chineseSymbol: string;
  chineseEmoji: string;
  chineseElement: string;
  polarity: string;
  celebrationHoroscope: string;
  dailyAffirmation: string;
}

export interface ZodiacCompatibility {
  birthdate1: string;
  birthdate2: string;
  sign1: string;
  sign1Emoji: string;
  sign2: string;
  sign2Emoji: string;
  compatibilityScore: number;
  elementHarmony: string;
  synergyDescription: string;
  tipForHarmony: string;
}
