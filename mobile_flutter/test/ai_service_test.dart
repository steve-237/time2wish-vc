import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/ai_service.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiService Unit & Fallback Tests', () {
    late ApiService apiService;
    late AiService aiService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      apiService = ApiService();
      aiService = AiService(apiService);
    });

    test('generateWish returns appropriate fallback wish per tone when offline', () async {
      final friendlyWish = await aiService.generateWish(birthdayId: 99, tone: 'FRIENDLY');
      expect(friendlyWish, contains('Joyeux anniversaire'));
      expect(friendlyWish, contains('rires'));

      final formalWish = await aiService.generateWish(birthdayId: 99, tone: 'FORMAL');
      expect(formalWish, contains('Je vous souhaite un très heureux anniversaire'));

      final romanticWish = await aiService.generateWish(birthdayId: 99, tone: 'ROMANTIC');
      expect(romanticWish, contains('mon cœur'));

      final poeticWish = await aiService.generateWish(birthdayId: 99, tone: 'POETIC');
      expect(poeticWish, contains('étoile'));
    });

    test('generateGiftSuggestions returns curated suggestions for category AMI', () async {
      final suggestions = await aiService.generateGiftSuggestions(
        birthdayId: 10,
        contactName: 'Lucas',
        category: 'Ami',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.length, greaterThanOrEqualTo(3));
      expect(suggestions.any((s) => s.name.contains('Bluetooth') || s.name.contains('Jeu')), isTrue);
    });

    test('generateGiftSuggestions returns curated suggestions for category FAMILLE', () async {
      final suggestions = await aiService.generateGiftSuggestions(
        birthdayId: 11,
        contactName: 'Maman',
        category: 'Famille',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.name.contains('Album photo') || s.name.contains('Diffuseur')), isTrue);
    });

    test('GiftSuggestionModel serialization and deserialization', () {
      final model = GiftSuggestionModel(
        name: 'Casque Audio Hi-Fi',
        estimatedPrice: '120€',
        whereToBuy: 'Fnac',
        purchaseLink: 'https://example.com/headphones',
        preparationTips: 'Idéal pour écouter du jazz.',
      );

      final json = model.toJson();
      expect(json['name'], equals('Casque Audio Hi-Fi'));
      expect(json['estimatedPrice'], equals('120€'));

      final restored = GiftSuggestionModel.fromJson(json);
      expect(restored.name, equals(model.name));
      expect(restored.whereToBuy, equals('Fnac'));
      expect(restored.purchaseLink, equals('https://example.com/headphones'));
    });
  });
}
