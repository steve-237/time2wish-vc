import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService & i18n / Theme Tests', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await Future.delayed(const Duration(milliseconds: 20));
    });

    tearDown(() {
      settingsService.dispose();
    });

    test('Initial defaults are dark theme and French language', () {
      expect(settingsService.themeMode, equals(ThemeMode.dark));
      expect(settingsService.isDarkMode, isTrue);
      expect(settingsService.language, equals('fr'));
    });

    test('toggleDarkMode toggles between dark and light modes', () async {
      expect(settingsService.themeMode, equals(ThemeMode.dark));

      await settingsService.toggleDarkMode();
      expect(settingsService.themeMode, equals(ThemeMode.light));
      expect(settingsService.isDarkMode, isFalse);

      await settingsService.toggleDarkMode();
      expect(settingsService.themeMode, equals(ThemeMode.dark));
      expect(settingsService.isDarkMode, isTrue);
    });

    test('setLanguage switches between fr, en, and de and ignores invalid locales', () async {
      await settingsService.setLanguage('en');
      expect(settingsService.language, equals('en'));

      await settingsService.setLanguage('de');
      expect(settingsService.language, equals('de'));

      await settingsService.setLanguage('es'); // unsupported
      expect(settingsService.language, equals('de'));

      await settingsService.setLanguage('fr');
      expect(settingsService.language, equals('fr'));
    });

    test('tr() provides accurate translations in French, English, and German', () async {
      await settingsService.setLanguage('fr');
      expect(settingsService.tr('dashboard'), equals('Tableau de bord'));
      expect(settingsService.tr('birthdays'), equals('Anniversaires'));
      expect(settingsService.tr('appearance'), equals('Apparence & Thème'));

      await settingsService.setLanguage('en');
      expect(settingsService.tr('dashboard'), equals('Dashboard'));
      expect(settingsService.tr('birthdays'), equals('Birthdays'));
      expect(settingsService.tr('appearance'), equals('Appearance & Theme'));

      await settingsService.setLanguage('de');
      expect(settingsService.tr('dashboard'), equals('Dashboard'));
      expect(settingsService.tr('birthdays'), equals('Geburtstage'));
      expect(settingsService.tr('appearance'), equals('Erscheinungsbild & Thema'));
    });

    test('tr() falls back to key if translation is missing', () {
      expect(settingsService.tr('non_existent_key_123'), equals('non_existent_key_123'));
    });
  });
}
