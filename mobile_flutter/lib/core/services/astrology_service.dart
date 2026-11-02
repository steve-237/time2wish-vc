import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/astrology_model.dart';
import 'api_service.dart';

class AstrologyService extends ChangeNotifier {
  final ApiService? _apiService;

  AstrologyService({ApiService? apiService}) : _apiService = apiService;

  /// Retrieves astrology insights for a given birthdate.
  /// Computes locally for immediate response (offline-first),
  /// and enhances via API if network is available.
  Future<AstrologyInsight> getInsights(DateTime birthdate, {String lang = 'fr'}) async {
    // 1. Instant local computation
    final localInsight = computeLocalInsights(birthdate, lang: lang);

    // 2. Optional remote enhancement if online
    if (_apiService != null) {
      try {
        final dateStr = birthdate.toIso8601String().substring(0, 10);
        final response = await _apiService!.get('/api/astrology/insights?birthdate=$dateStr&lang=$lang');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return AstrologyInsight.fromJson(data);
        }
      } catch (e) {
        debugPrint('AstrologyService API fallback to local: $e');
      }
    }

    return localInsight;
  }

  /// Calculates cosmic compatibility between two birthdates.
  Future<ZodiacCompatibility> calculateCompatibility(
    DateTime date1,
    DateTime date2, {
    String lang = 'fr',
  }) async {
    // 1. Instant local computation
    final localComp = computeLocalCompatibility(date1, date2, lang: lang);

    // 2. Optional remote enhancement if online
    if (_apiService != null) {
      try {
        final d1 = date1.toIso8601String().substring(0, 10);
        final d2 = date2.toIso8601String().substring(0, 10);
        final response = await _apiService!.get('/api/astrology/compatibility?date1=$d1&date2=$d2&lang=$lang');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return ZodiacCompatibility.fromJson(data);
        }
      } catch (e) {
        debugPrint('AstrologyService compatibility API fallback: $e');
      }
    }

    return localComp;
  }

  /// Standalone local astronomical computation engine
  static AstrologyInsight computeLocalInsights(DateTime birthdate, {String lang = 'fr'}) {
    final isEn = lang.startsWith('en');
    final western = _getWesternZodiac(birthdate);
    final chinese = _getChineseZodiac(birthdate);

    final String horoscope = isEn
        ? "Under the radiant influence of ${western['rulingPlanetEn']} and the noble aura of ${western['nameEn']}, this year marks a flourishing expansion for you. "
            "Your ${chinese['animalEn']} vitality and ${western['elementEn']} warmth draw inspiring opportunities, genuine joy, and loving celebrations into your life!"
        : "Sous les auspices bienveillants de ${western['rulingPlanetFr']} et la constellation du ${western['nameFr']}, cette nouvelle année personnelle s'ouvre sous le signe de l'expansion et de la réussite. "
            "Votre énergie de ${chinese['animalFr']} alliée à la noblesse de votre élément ${western['elementFr']} attire à vous des opportunités inspirantes, des amitiés fidèles et de vibrantes célébrations !";

    String affirmation;
    final elementKey = western['elementKey'] as String;
    if (isEn) {
      switch (elementKey) {
        case 'FIRE':
          affirmation = "I shine with confidence, warmth, and relentless creative passion.";
          break;
        case 'EARTH':
          affirmation = "I build lasting happiness, peace, and abundance with graceful determination.";
          break;
        case 'AIR':
          affirmation = "My mind is open to boundless wisdom, joy, and deep authentic connections.";
          break;
        case 'WATER':
        default:
          affirmation = "My heart flows with boundless intuition, kindness, and deep harmony.";
          break;
      }
    } else {
      switch (elementKey) {
        case 'FIRE':
          affirmation = "Je rayonne de confiance, d'enthousiasme et d'une force créatrice inaltérable.";
          break;
        case 'EARTH':
          affirmation = "Je construis mon bonheur et mes réussites avec constance, sagesse et sérénité.";
          break;
        case 'AIR':
          affirmation = "Mon esprit s'ouvre à des horizons infinis, à la joie et à des amitiés lumineuses.";
          break;
        case 'WATER':
        default:
          affirmation = "Mon intuition et ma sensibilité bienveillante sont des dons précieux pour mon entourage.";
          break;
      }
    }

    return AstrologyInsight(
      birthdate: birthdate,
      westernSign: isEn ? (western['nameEn'] as String) : (western['nameFr'] as String),
      westernSymbol: western['symbol'] as String,
      westernEmoji: western['emoji'] as String,
      westernDateRange: isEn ? (western['dateRangeEn'] as String) : (western['dateRangeFr'] as String),
      element: isEn ? (western['elementEn'] as String) : (western['elementFr'] as String),
      modality: isEn ? (western['modalityEn'] as String) : (western['modalityFr'] as String),
      rulingPlanet: isEn ? (western['rulingPlanetEn'] as String) : (western['rulingPlanetFr'] as String),
      personalityTraits: isEn
          ? List<String>.from(western['traitsEn'] as List)
          : List<String>.from(western['traitsFr'] as List),
      luckyNumbers: List<int>.from(western['luckyNumbers'] as List),
      luckyDays: isEn ? List<String>.from(western['daysEn'] as List) : List<String>.from(western['daysFr'] as List),
      luckyColors: isEn ? List<String>.from(western['colorsEn'] as List) : List<String>.from(western['colorsFr'] as List),
      compatibleSigns: isEn
          ? List<String>.from(western['compatibleEn'] as List)
          : List<String>.from(western['compatibleFr'] as List),
      chineseAnimal: isEn ? (chinese['animalEn'] as String) : (chinese['animalFr'] as String),
      chineseSymbol: chinese['symbol'] as String,
      chineseEmoji: chinese['emoji'] as String,
      chineseElement: isEn ? (chinese['elementEn'] as String) : (chinese['elementFr'] as String),
      polarity: chinese['polarity'] as String,
      celebrationHoroscope: horoscope,
      dailyAffirmation: affirmation,
    );
  }

  static ZodiacCompatibility computeLocalCompatibility(
    DateTime date1,
    DateTime date2, {
    String lang = 'fr',
  }) {
    final isEn = lang.startsWith('en');
    final w1 = _getWesternZodiac(date1);
    final w2 = _getWesternZodiac(date2);

    final e1 = w1['elementKey'] as String;
    final e2 = w2['elementKey'] as String;

    int score = 76;
    if (w1['nameFr'] == w2['nameFr']) {
      score = 88;
    } else if (e1 == e2) {
      score = 92;
    } else if ((e1 == 'FIRE' && e2 == 'AIR') || (e1 == 'AIR' && e2 == 'FIRE')) {
      score = 95;
    } else if ((e1 == 'EARTH' && e2 == 'WATER') || (e1 == 'WATER' && e2 == 'EARTH')) {
      score = 94;
    } else if ((e1 == 'AIR' && e2 == 'WATER') || (e1 == 'WATER' && e2 == 'AIR')) {
      score = 78;
    } else {
      score = 72;
    }

    String harmony;
    String synergy;
    String tip;

    final sign1Name = isEn ? (w1['nameEn'] as String) : (w1['nameFr'] as String);
    final sign2Name = isEn ? (w2['nameEn'] as String) : (w2['nameFr'] as String);

    if (isEn) {
      if (score >= 90) {
        harmony = "Cosmic Affinity (${w1['elementEn']} + ${w2['elementEn']})";
        synergy = "$sign1Name and $sign2Name share a vibrant natural connection that multiplies inspiration and shared happiness!";
      } else if (score >= 80) {
        harmony = "Warm & Balanced Bond (${w1['elementEn']} + ${w2['elementEn']})";
        synergy = "A deeply supportive partnership where both personalities bring out the best in each other.";
      } else {
        harmony = "Creative Contrast (${w1['elementEn']} + ${w2['elementEn']})";
        synergy = "An engaging bond full of stimulating growth through complementary perspectives.";
      }
      tip = "Celebrate your unique points of view and plan spontaneous celebrations together!";
    } else {
      if (score >= 90) {
        harmony = "Complicité Vibrante (${w1['elementFr']} + ${w2['elementFr']})";
        synergy = "$sign1Name et $sign2Name partagent une alchimie naturelle qui démultiplie l'inspiration et les projets communs !";
      } else if (score >= 80) {
        harmony = "Harmonie Chaleureuse (${w1['elementFr']} + ${w2['elementFr']})";
        synergy = "Une relation équilibrée et bienveillante où les qualités de l'un soutiennent harmonieusement celles de l'autre.";
      } else {
        harmony = "Complémentarité Stimulante (${w1['elementFr']} + ${w2['elementFr']})";
        synergy = "Une alliance riche en découvertes où vos contrastes deviennent une source constante d'enrichissement mutuel.";
      }
      tip = "Valorisez vos talents respectifs et organisez des célébrations régulières pour nourrir votre lien cosmique !";
    }

    return ZodiacCompatibility(
      birthdate1: date1,
      birthdate2: date2,
      sign1: sign1Name,
      sign1Emoji: w1['emoji'] as String,
      sign2: sign2Name,
      sign2Emoji: w2['emoji'] as String,
      compatibilityScore: score,
      elementHarmony: harmony,
      synergyDescription: synergy,
      tipForHarmony: tip,
    );
  }

  static Map<String, dynamic> _getWesternZodiac(DateTime date) {
    final month = date.month;
    final day = date.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return {
        'nameFr': 'Bélier', 'nameEn': 'Aries', 'symbol': '♈', 'emoji': '♈',
        'dateRangeFr': '21 mars - 19 avril', 'dateRangeEn': 'Mar 21 - Apr 19',
        'elementKey': 'FIRE', 'elementFr': 'Feu', 'elementEn': 'Fire',
        'modalityFr': 'Cardinal', 'modalityEn': 'Cardinal',
        'rulingPlanetFr': 'Mars', 'rulingPlanetEn': 'Mars',
        'traitsFr': ['Courageux', 'Pionnier', 'Énergique', 'Spontané'],
        'traitsEn': ['Courageous', 'Pioneering', 'Energetic', 'Spontaneous'],
        'luckyNumbers': [9, 18, 27],
        'daysFr': ['Mardi'], 'daysEn': ['Tuesday'],
        'colorsFr': ['Rouge', 'Corail'], 'colorsEn': ['Red', 'Coral'],
        'compatibleFr': ['Lion', 'Sagittaire', 'Verseau', 'Gémeaux'],
        'compatibleEn': ['Leo', 'Sagittarius', 'Aquarius', 'Gemini'],
      };
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return {
        'nameFr': 'Taureau', 'nameEn': 'Taurus', 'symbol': '♉', 'emoji': '♉',
        'dateRangeFr': '20 avril - 20 mai', 'dateRangeEn': 'Apr 20 - May 20',
        'elementKey': 'EARTH', 'elementFr': 'Terre', 'elementEn': 'Earth',
        'modalityFr': 'Fixe', 'modalityEn': 'Fixed',
        'rulingPlanetFr': 'Vénus', 'rulingPlanetEn': 'Venus',
        'traitsFr': ['Persévérant', 'Loyal', 'Généreux', 'Pragmatique'],
        'traitsEn': ['Steadfast', 'Loyal', 'Generous', 'Pragmatic'],
        'luckyNumbers': [6, 15, 24],
        'daysFr': ['Vendredi'], 'daysEn': ['Friday'],
        'colorsFr': ['Vert émeraude', 'Rose'], 'colorsEn': ['Emerald Green', 'Pink'],
        'compatibleFr': ['Vierge', 'Capricorne', 'Cancer', 'Poissons'],
        'compatibleEn': ['Virgo', 'Capricorn', 'Cancer', 'Pisces'],
      };
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return {
        'nameFr': 'Gémeaux', 'nameEn': 'Gemini', 'symbol': '♊', 'emoji': '♊',
        'dateRangeFr': '21 mai - 20 juin', 'dateRangeEn': 'May 21 - Jun 20',
        'elementKey': 'AIR', 'elementFr': 'Air', 'elementEn': 'Air',
        'modalityFr': 'Mutable', 'modalityEn': 'Mutable',
        'rulingPlanetFr': 'Mercure', 'rulingPlanetEn': 'Mercury',
        'traitsFr': ['Curieux', 'Éloquent', 'Vif d\'esprit', 'Adaptable'],
        'traitsEn': ['Curious', 'Eloquent', 'Quick-witted', 'Adaptable'],
        'luckyNumbers': [5, 14, 23],
        'daysFr': ['Mercredi'], 'daysEn': ['Wednesday'],
        'colorsFr': ['Jaune solaire', 'Bleu ciel'], 'colorsEn': ['Sunny Yellow', 'Sky Blue'],
        'compatibleFr': ['Balance', 'Verseau', 'Bélier', 'Lion'],
        'compatibleEn': ['Libra', 'Aquarius', 'Aries', 'Leo'],
      };
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return {
        'nameFr': 'Cancer', 'nameEn': 'Cancer', 'symbol': '♋', 'emoji': '♋',
        'dateRangeFr': '21 juin - 22 juillet', 'dateRangeEn': 'Jun 21 - Jul 22',
        'elementKey': 'WATER', 'elementFr': 'Eau', 'elementEn': 'Water',
        'modalityFr': 'Cardinal', 'modalityEn': 'Cardinal',
        'rulingPlanetFr': 'Lune', 'rulingPlanetEn': 'Moon',
        'traitsFr': ['Protecteur', 'Intuitif', 'Sensible', 'Dévoué'],
        'traitsEn': ['Protective', 'Intuitive', 'Empathetic', 'Devoted'],
        'luckyNumbers': [2, 7, 11],
        'daysFr': ['Lundi'], 'daysEn': ['Monday'],
        'colorsFr': ['Blanc perle', 'Argent'], 'colorsEn': ['Pearl White', 'Silver'],
        'compatibleFr': ['Scorpion', 'Poissons', 'Taureau', 'Vierge'],
        'compatibleEn': ['Scorpio', 'Pisces', 'Taurus', 'Virgo'],
      };
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return {
        'nameFr': 'Lion', 'nameEn': 'Leo', 'symbol': '♌', 'emoji': '♌',
        'dateRangeFr': '23 juillet - 22 août', 'dateRangeEn': 'Jul 23 - Aug 22',
        'elementKey': 'FIRE', 'elementFr': 'Feu', 'elementEn': 'Fire',
        'modalityFr': 'Fixe', 'modalityEn': 'Fixed',
        'rulingPlanetFr': 'Soleil', 'rulingPlanetEn': 'Sun',
        'traitsFr': ['Magnanime', 'Chaleureux', 'Rayonnant', 'Leader'],
        'traitsEn': ['Magnanimous', 'Warm-hearted', 'Radiant', 'Leader'],
        'luckyNumbers': [1, 10, 19],
        'daysFr': ['Dimanche'], 'daysEn': ['Sunday'],
        'colorsFr': ['Or', 'Ambre'], 'colorsEn': ['Gold', 'Amber'],
        'compatibleFr': ['Bélier', 'Sagittaire', 'Balance', 'Gémeaux'],
        'compatibleEn': ['Aries', 'Sagittarius', 'Libra', 'Gemini'],
      };
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return {
        'nameFr': 'Vierge', 'nameEn': 'Virgo', 'symbol': '♍', 'emoji': '♍',
        'dateRangeFr': '23 août - 22 septembre', 'dateRangeEn': 'Aug 23 - Sep 22',
        'elementKey': 'EARTH', 'elementFr': 'Terre', 'elementEn': 'Earth',
        'modalityFr': 'Mutable', 'modalityEn': 'Mutable',
        'rulingPlanetFr': 'Mercure', 'rulingPlanetEn': 'Mercury',
        'traitsFr': ['Méthodique', 'Bienveillant', 'Sensible', 'Perspicace'],
        'traitsEn': ['Methodical', 'Kind-hearted', 'Discerning', 'Insightful'],
        'luckyNumbers': [5, 14, 32],
        'daysFr': ['Mercredi'], 'daysEn': ['Wednesday'],
        'colorsFr': ['Bleu marine', 'Beige'], 'colorsEn': ['Navy Blue', 'Beige'],
        'compatibleFr': ['Taureau', 'Capricorne', 'Cancer', 'Scorpion'],
        'compatibleEn': ['Taurus', 'Capricorn', 'Cancer', 'Scorpio'],
      };
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return {
        'nameFr': 'Balance', 'nameEn': 'Libra', 'symbol': '♎', 'emoji': '♎',
        'dateRangeFr': '23 septembre - 22 octobre', 'dateRangeEn': 'Sep 23 - Oct 22',
        'elementKey': 'AIR', 'elementFr': 'Air', 'elementEn': 'Air',
        'modalityFr': 'Cardinal', 'modalityEn': 'Cardinal',
        'rulingPlanetFr': 'Vénus', 'rulingPlanetEn': 'Venus',
        'traitsFr': ['Harmonieux', 'Juste', 'Diplomate', 'Raffiné'],
        'traitsEn': ['Harmonious', 'Fair-minded', 'Diplomatic', 'Refined'],
        'luckyNumbers': [6, 15, 24],
        'daysFr': ['Vendredi'], 'daysEn': ['Friday'],
        'colorsFr': ['Bleu pastel', 'Rose pêche'], 'colorsEn': ['Pastel Blue', 'Peach Pink'],
        'compatibleFr': ['Gémeaux', 'Verseau', 'Lion', 'Sagittaire'],
        'compatibleEn': ['Gemini', 'Aquarius', 'Leo', 'Sagittarius'],
      };
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return {
        'nameFr': 'Scorpion', 'nameEn': 'Scorpio', 'symbol': '♏', 'emoji': '♏',
        'dateRangeFr': '23 octobre - 21 novembre', 'dateRangeEn': 'Oct 23 - Nov 21',
        'elementKey': 'WATER', 'elementFr': 'Eau', 'elementEn': 'Water',
        'modalityFr': 'Fixe', 'modalityEn': 'Fixed',
        'rulingPlanetFr': 'Pluton', 'rulingPlanetEn': 'Pluto',
        'traitsFr': ['Passionné', 'Magnétique', 'Résolu', 'Loyal'],
        'traitsEn': ['Passionate', 'Magnetic', 'Determined', 'Loyal'],
        'luckyNumbers': [8, 17, 26],
        'daysFr': ['Mardi'], 'daysEn': ['Tuesday'],
        'colorsFr': ['Pourpre', 'Bordeaux'], 'colorsEn': ['Crimson', 'Burgundy'],
        'compatibleFr': ['Cancer', 'Poissons', 'Vierge', 'Capricorne'],
        'compatibleEn': ['Cancer', 'Pisces', 'Virgo', 'Capricorn'],
      };
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return {
        'nameFr': 'Sagittaire', 'nameEn': 'Sagittarius', 'symbol': '♐', 'emoji': '♐',
        'dateRangeFr': '22 novembre - 21 décembre', 'dateRangeEn': 'Nov 22 - Dec 21',
        'elementKey': 'FIRE', 'elementFr': 'Feu', 'elementEn': 'Fire',
        'modalityFr': 'Mutable', 'modalityEn': 'Mutable',
        'rulingPlanetFr': 'Jupiter', 'rulingPlanetEn': 'Jupiter',
        'traitsFr': ['Optimiste', 'Visionnaire', 'Aventurier', 'Généreux'],
        'traitsEn': ['Optimistic', 'Visionary', 'Adventurous', 'Generous'],
        'luckyNumbers': [3, 12, 21],
        'daysFr': ['Jeudi'], 'daysEn': ['Thursday'],
        'colorsFr': ['Violet royal', 'Indigo'], 'colorsEn': ['Royal Purple', 'Indigo'],
        'compatibleFr': ['Bélier', 'Lion', 'Balance', 'Verseau'],
        'compatibleEn': ['Aries', 'Leo', 'Libra', 'Aquarius'],
      };
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return {
        'nameFr': 'Capricorne', 'nameEn': 'Capricorn', 'symbol': '♑', 'emoji': '♑',
        'dateRangeFr': '22 décembre - 19 janvier', 'dateRangeEn': 'Dec 22 - Jan 19',
        'elementKey': 'EARTH', 'elementFr': 'Terre', 'elementEn': 'Earth',
        'modalityFr': 'Cardinal', 'modalityEn': 'Cardinal',
        'rulingPlanetFr': 'Saturne', 'rulingPlanetEn': 'Saturn',
        'traitsFr': ['Ambitieux', 'Sage', 'Discipliné', 'Fiable'],
        'traitsEn': ['Ambitious', 'Wise', 'Disciplined', 'Dependable'],
        'luckyNumbers': [4, 13, 22],
        'daysFr': ['Samedi'], 'daysEn': ['Saturday'],
        'colorsFr': ['Gris ardoise', 'Marron chaud'], 'colorsEn': ['Slate Gray', 'Warm Brown'],
        'compatibleFr': ['Taureau', 'Vierge', 'Scorpion', 'Poissons'],
        'compatibleEn': ['Taurus', 'Virgo', 'Scorpio', 'Pisces'],
      };
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return {
        'nameFr': 'Verseau', 'nameEn': 'Aquarius', 'symbol': '♒', 'emoji': '♒',
        'dateRangeFr': '20 janvier - 18 février', 'dateRangeEn': 'Jan 20 - Feb 18',
        'elementKey': 'AIR', 'elementFr': 'Air', 'elementEn': 'Air',
        'modalityFr': 'Fixe', 'modalityEn': 'Fixed',
        'rulingPlanetFr': 'Uranus', 'rulingPlanetEn': 'Uranus',
        'traitsFr': ['Innovant', 'Humaniste', 'Idéaliste', 'Fraternel'],
        'traitsEn': ['Innovative', 'Humanitarian', 'Idealistic', 'Brotherly'],
        'luckyNumbers': [4, 7, 11],
        'daysFr': ['Samedi'], 'daysEn': ['Saturday'],
        'colorsFr': ['Bleu électrique', 'Turquoise'], 'colorsEn': ['Electric Blue', 'Turquoise'],
        'compatibleFr': ['Gémeaux', 'Balance', 'Bélier', 'Sagittaire'],
        'compatibleEn': ['Gemini', 'Libra', 'Aries', 'Sagittarius'],
      };
    }

    return {
      'nameFr': 'Poissons', 'nameEn': 'Pisces', 'symbol': '♓', 'emoji': '♓',
      'dateRangeFr': '19 février - 20 mars', 'dateRangeEn': 'Feb 19 - Mar 20',
      'elementKey': 'WATER', 'elementFr': 'Eau', 'elementEn': 'Water',
      'modalityFr': 'Mutable', 'modalityEn': 'Mutable',
      'rulingPlanetFr': 'Neptune', 'rulingPlanetEn': 'Neptune',
      'traitsFr': ['Empathique', 'Créatif', 'Rêveur', 'Généreux'],
      'traitsEn': ['Empathetic', 'Creative', 'Dreamer', 'Generous'],
      'luckyNumbers': [3, 7, 12],
      'daysFr': ['Jeudi'], 'daysEn': ['Thursday'],
      'colorsFr': ['Vert d\'eau', 'Bleu marine'], 'colorsEn': ['Sea Green', 'Sea Navy'],
      'compatibleFr': ['Cancer', 'Scorpion', 'Taureau', 'Capricorne'],
      'compatibleEn': ['Cancer', 'Scorpio', 'Taurus', 'Capricorn'],
    };
  }

  static Map<String, dynamic> _getChineseZodiac(DateTime date) {
    final year = date.year;
    final animals = [
      {'fr': 'Rat', 'en': 'Rat', 'symbol': '鼠', 'emoji': '🐀'},
      {'fr': 'Bœuf', 'en': 'Ox', 'symbol': '牛', 'emoji': '🐂'},
      {'fr': 'Tigre', 'en': 'Tiger', 'symbol': '虎', 'emoji': '🐅'},
      {'fr': 'Lapin', 'en': 'Rabbit', 'symbol': '兔', 'emoji': '🐇'},
      {'fr': 'Dragon', 'en': 'Dragon', 'symbol': '龙', 'emoji': '🐉'},
      {'fr': 'Serpent', 'en': 'Snake', 'symbol': '蛇', 'emoji': '🐍'},
      {'fr': 'Cheval', 'en': 'Horse', 'symbol': '马', 'emoji': '🐎'},
      {'fr': 'Chèvre', 'en': 'Goat', 'symbol': '羊', 'emoji': '🐐'},
      {'fr': 'Singe', 'en': 'Monkey', 'symbol': '猴', 'emoji': '🐒'},
      {'fr': 'Coq', 'en': 'Rooster', 'symbol': '鸡', 'emoji': '🐓'},
      {'fr': 'Chien', 'en': 'Dog', 'symbol': '狗', 'emoji': '🐕'},
      {'fr': 'Cochon', 'en': 'Pig', 'symbol': '猪', 'emoji': '🐖'},
    ];

    final animalIndex = (year - 4) % 12;
    final selectedAnimal = animals[animalIndex >= 0 ? animalIndex : (animalIndex + 12)];

    final lastDigit = (year.abs()) % 10;
    String elFr;
    String elEn;
    if (lastDigit == 0 || lastDigit == 1) {
      elFr = 'Métal';
      elEn = 'Metal';
    } else if (lastDigit == 2 || lastDigit == 3) {
      elFr = 'Eau';
      elEn = 'Water';
    } else if (lastDigit == 4 || lastDigit == 5) {
      elFr = 'Bois';
      elEn = 'Wood';
    } else if (lastDigit == 6 || lastDigit == 7) {
      elFr = 'Feu';
      elEn = 'Fire';
    } else {
      elFr = 'Terre';
      elEn = 'Earth';
    }

    final polarity = (year % 2 == 0) ? 'Yang' : 'Yin';

    return {
      'animalFr': selectedAnimal['fr'],
      'animalEn': selectedAnimal['en'],
      'symbol': selectedAnimal['symbol'],
      'emoji': selectedAnimal['emoji'],
      'elementFr': elFr,
      'elementEn': elEn,
      'polarity': polarity,
    };
  }
}
