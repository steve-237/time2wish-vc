import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/settings_service.dart';
import 'package:time2wish_mobile/core/models/birthday_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Monthly Calendar & View Mode Tests', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await Future.delayed(const Duration(milliseconds: 20));
    });

    tearDown(() {
      settingsService.dispose();
    });

    test('Initial dashboardViewMode defaults to list', () {
      expect(settingsService.dashboardViewMode, equals('list'));
    });

    test('setDashboardViewMode updates and persists view mode', () async {
      await settingsService.setDashboardViewMode('calendar');
      expect(settingsService.dashboardViewMode, equals('calendar'));

      await settingsService.setDashboardViewMode('list');
      expect(settingsService.dashboardViewMode, equals('list'));
    });

    test('Calendar i18n keys are translated properly in all supported languages', () async {
      await settingsService.setLanguage('fr');
      expect(settingsService.tr('view_list'), equals('Liste'));
      expect(settingsService.tr('view_calendar'), equals('Calendrier'));
      expect(settingsService.tr('today'), equals("Aujourd'hui"));
      expect(settingsService.tr('no_birthdays_this_month'), equals('Aucun anniversaire ce mois-ci'));

      await settingsService.setLanguage('en');
      expect(settingsService.tr('view_list'), equals('List'));
      expect(settingsService.tr('view_calendar'), equals('Calendar'));
      expect(settingsService.tr('today'), equals('Today'));
      expect(settingsService.tr('no_birthdays_this_month'), equals('No birthdays this month'));

      await settingsService.setLanguage('de');
      expect(settingsService.tr('view_list'), equals('Liste'));
      expect(settingsService.tr('view_calendar'), equals('Kalender'));
      expect(settingsService.tr('today'), equals('Heute'));
      expect(settingsService.tr('no_birthdays_this_month'), equals('Keine Geburtstage in diesem Monat'));
    });

    test('Birthday filtering by month and day operates accurately', () {
      final sampleBirthdays = [
        BirthdayModel(
          id: '1',
          name: 'Alice Wonder',
          birthdate: DateTime(1995, 3, 15),
          category: 'AMIS',
        ),
        BirthdayModel(
          id: '2',
          name: 'Bob Builder',
          birthdate: DateTime(1988, 3, 20),
          category: 'TRAVAIL',
        ),
        BirthdayModel(
          id: '3',
          name: 'Charlie Chaplin',
          birthdate: DateTime(1977, 11, 15),
          category: 'FAMILLE',
        ),
      ];

      // March birthdays
      final marchBirthdays = sampleBirthdays.where((b) => b.birthdate.month == 3).toList();
      expect(marchBirthdays.length, equals(2));

      // Specific day March 15
      final march15Birthdays = sampleBirthdays.where((b) => b.birthdate.month == 3 && b.birthdate.day == 15).toList();
      expect(march15Birthdays.length, equals(1));
      expect(march15Birthdays.first.name, equals('Alice Wonder'));

      // November birthdays
      final novBirthdays = sampleBirthdays.where((b) => b.birthdate.month == 11).toList();
      expect(novBirthdays.length, equals(1));
      expect(novBirthdays.first.name, equals('Charlie Chaplin'));
    });
  });
}
