import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/core/services/astrology_service.dart';

void main() {
  group('AstrologyService Mobile Astronomical Calculations', () {
    test('Calculates Western Zodiac signs accurately', () {
      final aries = AstrologyService.computeLocalInsights(DateTime(1995, 3, 21), lang: 'fr');
      expect(aries.westernSign, 'Bélier');
      expect(aries.element, 'Feu');
      expect(aries.westernEmoji, '♈');
      expect(aries.rulingPlanet, 'Mars');
      expect(aries.luckyNumbers, isNotEmpty);

      final taurus = AstrologyService.computeLocalInsights(DateTime(1992, 4, 25), lang: 'fr');
      expect(taurus.westernSign, 'Taureau');
      expect(taurus.element, 'Terre');

      final leoEn = AstrologyService.computeLocalInsights(DateTime(2001, 8, 10), lang: 'en');
      expect(leoEn.westernSign, 'Leo');
      expect(leoEn.element, 'Fire');
      expect(leoEn.rulingPlanet, 'Sun');

      final pisces = AstrologyService.computeLocalInsights(DateTime(1996, 3, 5), lang: 'fr');
      expect(pisces.westernSign, 'Poissons');
      expect(pisces.element, 'Eau');
    });

    test('Calculates Chinese Zodiac animal and element accurately', () {
      // 1984 -> Wood Rat
      final r1984 = AstrologyService.computeLocalInsights(DateTime(1984, 5, 10), lang: 'fr');
      expect(r1984.chineseAnimal, 'Rat');
      expect(r1984.chineseElement, 'Bois');
      expect(r1984.polarity, 'Yang');

      // 1990 -> Metal Horse
      final r1990 = AstrologyService.computeLocalInsights(DateTime(1990, 8, 20), lang: 'fr');
      expect(r1990.chineseAnimal, 'Cheval');
      expect(r1990.chineseElement, 'Métal');

      // 2024 -> Wood Dragon
      final r2024 = AstrologyService.computeLocalInsights(DateTime(2024, 2, 10), lang: 'en');
      expect(r2024.chineseAnimal, 'Dragon');
      expect(r2024.chineseElement, 'Wood');
    });

    test('Generates positive celebration horoscope and affirmation', () {
      final insight = AstrologyService.computeLocalInsights(DateTime(1994, 7, 28), lang: 'fr');
      expect(insight.celebrationHoroscope, contains('Lion'));
      expect(insight.dailyAffirmation, isNotEmpty);
      expect(insight.personalityTraits, isNotEmpty);
    });

    test('Calculates cosmic compatibility synergy between two dates', () {
      final comp = AstrologyService.computeLocalCompatibility(
        DateTime(1990, 8, 1), // Leo (Fire)
        DateTime(1992, 4, 5), // Aries (Fire)
        lang: 'fr',
      );

      expect(comp.compatibilityScore, greaterThanOrEqualTo(85));
      expect(comp.sign1, 'Lion');
      expect(comp.sign2, 'Bélier');
      expect(comp.elementHarmony, contains('Feu'));
      expect(comp.synergyDescription, isNotEmpty);
      expect(comp.tipForHarmony, isNotEmpty);
    });
  });
}
