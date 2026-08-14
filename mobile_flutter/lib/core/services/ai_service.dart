import 'package:flutter/material.dart';
import 'api_service.dart';

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
        if (extraInstructions != null) 'extraInstructions': extraInstructions,
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

  /// Get demo wish based on tone
  String _getDemoWish(String tone) {
    switch (tone.toUpperCase()) {
      case 'FORMAL':
        return 'Je vous souhaite un très heureux anniversaire. '
            'Que cette nouvelle année de vie vous apporte santé, '
            'bonheur et réussite dans tous vos projets. '
            'Avec mes sincères félicitations. 🎂✨';
      case 'HUMOROUS':
        return 'Joyeux anniversaire ! 🎉 On dit que le vin se bonifie '
            'avec l\'âge... alors tu dois être un grand cru maintenant ! '
            'Profite bien de ta journée, tu le mérites '
            '(même si tu commences à oublier ton âge 😄). '
            'Allez, champagne ! 🥂';
      case 'ROMANTIC':
        return 'En ce jour si spécial, je voulais te dire à quel point '
            'tu illumines ma vie. Chaque moment passé à tes côtés est '
            'un cadeau précieux. Joyeux anniversaire mon cœur, '
            'aujourd\'hui et pour toujours. 💕🌹';
      case 'POETIC':
        return 'Comme une étoile qui brille dans la nuit,\n'
            'Tu éclaires le monde par ta douce lumière.\n'
            'En ce jour béni où tu vis le jour,\n'
            'Le ciel entier célèbre ton amour.\n'
            'Joyeux anniversaire, âme précieuse. 🌟✨';
      case 'FRIENDLY':
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
