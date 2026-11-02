import 'dart:convert';

class AstrologyInsight {
  final DateTime birthdate;
  final String westernSign;
  final String westernSymbol;
  final String westernEmoji;
  final String westernDateRange;
  final String element;
  final String modality;
  final String rulingPlanet;
  final List<String> personalityTraits;
  final List<int> luckyNumbers;
  final List<String> luckyDays;
  final List<String> luckyColors;
  final List<String> compatibleSigns;
  final String chineseAnimal;
  final String chineseSymbol;
  final String chineseEmoji;
  final String chineseElement;
  final String polarity;
  final String celebrationHoroscope;
  final String dailyAffirmation;

  const AstrologyInsight({
    required this.birthdate,
    required this.westernSign,
    required this.westernSymbol,
    required this.westernEmoji,
    required this.westernDateRange,
    required this.element,
    required this.modality,
    required this.rulingPlanet,
    required this.personalityTraits,
    required this.luckyNumbers,
    required this.luckyDays,
    required this.luckyColors,
    required this.compatibleSigns,
    required this.chineseAnimal,
    required this.chineseSymbol,
    required this.chineseEmoji,
    required this.chineseElement,
    required this.polarity,
    required this.celebrationHoroscope,
    required this.dailyAffirmation,
  });

  factory AstrologyInsight.fromJson(Map<String, dynamic> json) {
    return AstrologyInsight(
      birthdate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      westernSign: json['westernSign'] as String? ?? '',
      westernSymbol: json['westernSymbol'] as String? ?? '',
      westernEmoji: json['westernEmoji'] as String? ?? '✨',
      westernDateRange: json['westernDateRange'] as String? ?? '',
      element: json['element'] as String? ?? 'Feu',
      modality: json['modality'] as String? ?? '',
      rulingPlanet: json['rulingPlanet'] as String? ?? '',
      personalityTraits: (json['personalityTraits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      luckyNumbers: (json['luckyNumbers'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? 7)
              .toList() ??
          [7],
      luckyDays: (json['luckyDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      luckyColors: (json['luckyColors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      compatibleSigns: (json['compatibleSigns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chineseAnimal: json['chineseAnimal'] as String? ?? '',
      chineseSymbol: json['chineseSymbol'] as String? ?? '',
      chineseEmoji: json['chineseEmoji'] as String? ?? '🐉',
      chineseElement: json['chineseElement'] as String? ?? 'Bois',
      polarity: json['polarity'] as String? ?? 'Yang',
      celebrationHoroscope: json['celebrationHoroscope'] as String? ?? '',
      dailyAffirmation: json['dailyAffirmation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'birthdate': birthdate.toIso8601String().substring(0, 10),
      'westernSign': westernSign,
      'westernSymbol': westernSymbol,
      'westernEmoji': westernEmoji,
      'westernDateRange': westernDateRange,
      'element': element,
      'modality': modality,
      'rulingPlanet': rulingPlanet,
      'personalityTraits': personalityTraits,
      'luckyNumbers': luckyNumbers,
      'luckyDays': luckyDays,
      'luckyColors': luckyColors,
      'compatibleSigns': compatibleSigns,
      'chineseAnimal': chineseAnimal,
      'chineseSymbol': chineseSymbol,
      'chineseEmoji': chineseEmoji,
      'chineseElement': chineseElement,
      'polarity': polarity,
      'celebrationHoroscope': celebrationHoroscope,
      'dailyAffirmation': dailyAffirmation,
    };
  }
}

class ZodiacCompatibility {
  final DateTime birthdate1;
  final DateTime birthdate2;
  final String sign1;
  final String sign1Emoji;
  final String sign2;
  final String sign2Emoji;
  final int compatibilityScore;
  final String elementHarmony;
  final String synergyDescription;
  final String tipForHarmony;

  const ZodiacCompatibility({
    required this.birthdate1,
    required this.birthdate2,
    required this.sign1,
    required this.sign1Emoji,
    required this.sign2,
    required this.sign2Emoji,
    required this.compatibilityScore,
    required this.elementHarmony,
    required this.synergyDescription,
    required this.tipForHarmony,
  });

  factory ZodiacCompatibility.fromJson(Map<String, dynamic> json) {
    return ZodiacCompatibility(
      birthdate1: json['birthdate1'] != null
          ? DateTime.tryParse(json['birthdate1'].toString()) ?? DateTime.now()
          : DateTime.now(),
      birthdate2: json['birthdate2'] != null
          ? DateTime.tryParse(json['birthdate2'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sign1: json['sign1'] as String? ?? '',
      sign1Emoji: json['sign1Emoji'] as String? ?? '✨',
      sign2: json['sign2'] as String? ?? '',
      sign2Emoji: json['sign2Emoji'] as String? ?? '✨',
      compatibilityScore: json['compatibilityScore'] as int? ?? 85,
      elementHarmony: json['elementHarmony'] as String? ?? '',
      synergyDescription: json['synergyDescription'] as String? ?? '',
      tipForHarmony: json['tipForHarmony'] as String? ?? '',
    );
  }
}
