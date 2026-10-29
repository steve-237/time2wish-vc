import 'package:flutter/material.dart';
import 'api_service.dart';

class GiftSuggestionModel {
  final String name;
  final String estimatedPrice;
  final String whereToBuy;
  final String? purchaseLink;
  final String? imageUrl;
  final String? preparationTips;

  GiftSuggestionModel({
    required this.name,
    required this.estimatedPrice,
    required this.whereToBuy,
    this.purchaseLink,
    this.imageUrl,
    this.preparationTips,
  });

  factory GiftSuggestionModel.fromJson(Map<String, dynamic> json) {
    return GiftSuggestionModel(
      name: json['name'] ?? '',
      estimatedPrice: json['estimatedPrice'] ?? '',
      whereToBuy: json['whereToBuy'] ?? '',
      purchaseLink: json['purchaseLink'],
      imageUrl: json['imageUrl'],
      preparationTips: json['preparationTips'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'estimatedPrice': estimatedPrice,
      'whereToBuy': whereToBuy,
      'purchaseLink': purchaseLink,
      'imageUrl': imageUrl,
      'preparationTips': preparationTips,
    };
  }
}

class AiService {
  final ApiService _apiService;

  AiService(this._apiService);

  /// Generate a personalized wish message via AI
  Future<String> generateWish({
    required int birthdayId,
    String tone = 'FRIENDLY',
    String lang = 'fr',
    String? extraInstructions,
  }) async {
    try {
      final response = await _apiService.dio.post('/ai/generate', data: {
        'birthdayId': birthdayId,
        'tone': tone,
        'lang': lang,
        if (extraInstructions != null && extraInstructions.isNotEmpty)
          'extraInstructions': extraInstructions,
      });

      if (response.statusCode == 200 && response.data != null) {
        return response.data['message'] ?? 'Joyeux anniversaire ! 🎂';
      }
    } catch (e) {
      debugPrint('[AiService] API offline, using demo wish: $e');
    }

    // Demo fallback wishes
    return _getDemoWish(tone);
  }

  /// Generate smart gift suggestions based on contact profile
  Future<List<GiftSuggestionModel>> generateGiftSuggestions({
    required int birthdayId,
    String? contactName,
    String? category,
  }) async {
    try {
      final response = await _apiService.dio.get('/birthdays/$birthdayId/generate-gifts');
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['suggestions'] as List?) ?? [];
        if (list.isNotEmpty) {
          return list.map((item) => GiftSuggestionModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('[AiService] API offline for gift suggestions, using local curated ideas: $e');
    }

    return _getCuratedGiftSuggestions(category: category, name: contactName);
  }

  /// Curated fallback suggestions
  List<GiftSuggestionModel> _getCuratedGiftSuggestions({String? category, String? name}) {
    final cat = (category ?? '').toUpperCase();
    if (cat.contains('FAMILLE') || cat.contains('FAMILY')) {
      return [
        GiftSuggestionModel(
          name: 'Album photo relié souvenirs de famille',
          estimatedPrice: '35€ - 50€',
          whereToBuy: 'Cheerz / Photobox',
          preparationTips: 'Rassemblez les meilleures photos de l\'année passée.',
        ),
        GiftSuggestionModel(
          name: 'Diffuseur d\'huiles essentielles ultrasonique',
          estimatedPrice: '30€ - 45€',
          whereToBuy: 'Nature & Découvertes',
          preparationTips: 'Fournissez un flacon d\'huile essentielle relaxante (lavande).',
        ),
        GiftSuggestionModel(
          name: 'Coffret gastronomique du terroir',
          estimatedPrice: '50€ - 75€',
          whereToBuy: 'Producteur local / Épicerie',
          preparationTips: 'Assortiment sucré-salé avec produits régionaux.',
        ),
      ];
    } else if (cat.contains('AMI') || cat.contains('FRIEND')) {
      return [
        GiftSuggestionModel(
          name: 'Enceinte Bluetooth nomade & étanche',
          estimatedPrice: '45€ - 65€',
          whereToBuy: 'Fnac / Darty / Amazon',
          preparationTips: 'Parfait pour les soirées entre amis et les sorties en plein air.',
        ),
        GiftSuggestionModel(
          name: 'Jeu de société d\'ambiance (Codenames ou Skyjo)',
          estimatedPrice: '20€ - 25€',
          whereToBuy: 'Boutique de jeux / Cultura',
          preparationTips: 'Idéal à tester le jour même de la fête !',
        ),
        GiftSuggestionModel(
          name: 'Coffret dégustation bières artisanales ou thés bios',
          estimatedPrice: '30€ - 40€',
          whereToBuy: 'Caviste ou épicerie fine locale',
          preparationTips: 'Accompagnez d\'une carte personnalisée.',
        ),
      ];
    } else if (cat.contains('PRO') || cat.contains('COLLEGUE')) {
      return [
        GiftSuggestionModel(
          name: 'Carnet de notes Moleskine avec stylo premium',
          estimatedPrice: '25€ - 35€',
          whereToBuy: 'Papeterie / Amazon',
          preparationTips: 'Un classique élégant toujours utile au quotidien.',
        ),
        GiftSuggestionModel(
          name: 'Mug isotherme en acier inoxydable (Ember ou Stanley)',
          estimatedPrice: '25€ - 40€',
          whereToBuy: 'Boutique design ou en ligne',
          preparationTips: 'Garde le café chaud toute la matinée au bureau.',
        ),
        GiftSuggestionModel(
          name: 'Carte cadeau culture ou librairie',
          estimatedPrice: '30€',
          whereToBuy: 'Fnac / Furet du Nord / Decitre',
          preparationTips: 'Laissez-le choisir ses lectures coups de cœur.',
        ),
      ];
    }

    // Default suggestions
    return [
      GiftSuggestionModel(
        name: 'Écouteurs sans fil avec réduction de bruit active',
        estimatedPrice: '50€ - 90€',
        whereToBuy: 'Fnac / Boulanger / Amazon',
        preparationTips: 'Un incontournable moderne très apprécié.',
      ),
      GiftSuggestionModel(
        name: 'Box expérience détente ou restaurant gourmand',
        estimatedPrice: '49€ - 99€',
        whereToBuy: 'Smartbox / Wonderbox',
        preparationTips: 'Valable 3 ans pour une escapade ou un bon moment.',
      ),
      GiftSuggestionModel(
        name: 'Plante verte d\'intérieur facile (Monstera ou Pilea)',
        estimatedPrice: '20€ - 35€',
        whereToBuy: 'Jardinerie / Fleuriste local',
        preparationTips: 'Offrez-la dans un joli cache-pot en céramique.',
      ),
    ];
  }

  /// Get demo wish based on tone
  String _getDemoWish(String tone) {
    switch (tone.toUpperCase()) {
      case 'FORMAL':
      case 'FORMEL':
        return 'Je vous souhaite un très heureux anniversaire. '
            'Que cette nouvelle année de vie vous apporte santé, '
            'bonheur et réussite dans tous vos projets. '
            'Avec mes sincères félicitations. 🎂✨';
      case 'HUMOROUS':
      case 'DROLE':
      case 'HUMORISTIQUE':
        return 'Joyeux anniversaire ! 🎉 On dit que le vin se bonifie '
            'avec l\'âge... alors tu dois être un grand cru maintenant ! '
            'Profite bien de ta journée, tu le mérites '
            '(même si tu commences à oublier ton âge 😄). '
            'Allez, champagne ! 🥂';
      case 'ROMANTIC':
      case 'ROMANTIQUE':
        return 'En ce jour si spécial, je voulais te dire à quel point '
            'tu illumines ma vie. Chaque moment passé à tes côtés est '
            'un cadeau précieux. Joyeux anniversaire mon cœur, '
            'aujourd\'hui et pour toujours. 💕🌹';
      case 'POETIC':
      case 'POETIQUE':
        return 'Comme une étoile qui brille dans la nuit,\n'
            'Tu éclaires le monde par ta douce lumière.\n'
            'En ce jour béni où tu vis le jour,\n'
            'Le ciel entier célèbre ton amour.\n'
            'Joyeux anniversaire, âme précieuse. 🌟✨';
      case 'FRIENDLY':
      case 'AMICAL':
      default:
        return 'Hey ! Joyeux anniversaire ! 🎂🎉 '
            'Que cette journée soit remplie de rires, de surprises '
            'et de moments inoubliables avec les gens que tu aimes. '
            'Profite à fond, tu le mérites ! '
            'Gros bisous et à très vite pour fêter ça ! 🥳💛';
    }
  }

  /// Available tones for wish generation
  static const List<Map<String, String>> tones = [
    {'key': 'FRIENDLY', 'label': 'Amical 😊', 'icon': '😊'},
    {'key': 'FORMAL', 'label': 'Formel 🎩', 'icon': '🎩'},
    {'key': 'HUMOROUS', 'label': 'Humoristique 😄', 'icon': '😄'},
    {'key': 'ROMANTIC', 'label': 'Romantique 💕', 'icon': '💕'},
    {'key': 'POETIC', 'label': 'Poétique 🌟', 'icon': '🌟'},
  ];
}
