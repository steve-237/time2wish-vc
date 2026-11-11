import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/birthday_model.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';
import 'package:time2wish_mobile/core/services/birthday_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Birthday Past Filtering & Dashboard Separation Tests (#83)', () {
    test('Already celebrated birthdays this year are excluded from upcoming and placed in pastBirthdays', () async {
      final now = DateTime.now();
      final todayDate = DateTime(1992, now.month, now.day);

      // Build dates strictly within current calendar year where possible
      final pastCandidate = now.subtract(const Duration(days: 2));
      final futureCandidate = now.add(const Duration(days: 5));

      final pastBirthdate = pastCandidate.year == now.year
          ? DateTime(1990, pastCandidate.month, pastCandidate.day)
          : DateTime(1990, 1, 1);

      final futureBirthdate = futureCandidate.year == now.year
          ? DateTime(1995, futureCandidate.month, futureCandidate.day)
          : DateTime(1995, 12, 31);

      final seedList = [
        BirthdayModel(id: 101, name: 'Already Celebrated', birthdate: pastBirthdate, category: 'AMIS').toJson(),
        BirthdayModel(id: 102, name: 'Today Celebration', birthdate: todayDate, category: 'FAMILLE').toJson(),
        BirthdayModel(id: 103, name: 'Future Celebration', birthdate: futureBirthdate, category: 'TRAVAIL').toJson(),
      ];

      SharedPreferences.setMockInitialValues({
        't2w_local_birthdays': jsonEncode(seedList),
      });

      final apiService = ApiService();
      final birthdayService = BirthdayService(apiService);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify model flags
      final celebrated = birthdayService.getBirthdayById(101)!;
      final todayBday = birthdayService.getBirthdayById(102)!;
      final futureBday = birthdayService.getBirthdayById(103)!;

      if (pastCandidate.year == now.year) {
        expect(celebrated.isPastThisYear, isTrue);
        expect(birthdayService.upcoming.any((b) => b.id == 101), isFalse);
        expect(birthdayService.pastBirthdays.any((b) => b.id == 101), isTrue);
      }

      // Today's birthday must remain in upcoming and not be in pastBirthdays
      expect(todayBday.isToday, isTrue);
      expect(todayBday.isPastThisYear, isFalse);
      expect(birthdayService.upcoming.any((b) => b.id == 102), isTrue);
      expect(birthdayService.pastBirthdays.any((b) => b.id == 102), isFalse);

      // Future birthday in same year must remain in upcoming
      if (futureCandidate.year == now.year) {
        expect(futureBday.isPastThisYear, isFalse);
        expect(birthdayService.upcoming.any((b) => b.id == 103), isTrue);
        expect(birthdayService.pastBirthdays.any((b) => b.id == 103), isFalse);
      }

      // First item in upcoming must be Today Celebration (daysRemaining == 0)
      expect(birthdayService.upcoming.first.id, equals(102));
      expect(birthdayService.upcoming.first.daysRemaining, equals(0));
    });

    test('upcomingThisMonth excludes past birthdays from earlier in the current month', () async {
      final now = DateTime.now();
      // Only execute past-in-same-month check if today is not the 1st of the month
      if (now.day > 1) {
        final pastSameMonth = DateTime(1988, now.month, now.day - 1);
        final todaySameMonth = DateTime(1993, now.month, now.day);

        final seedList = [
          BirthdayModel(id: 201, name: 'Past This Month', birthdate: pastSameMonth, category: 'AMIS').toJson(),
          BirthdayModel(id: 202, name: 'Today This Month', birthdate: todaySameMonth, category: 'AMIS').toJson(),
        ];

        SharedPreferences.setMockInitialValues({
          't2w_local_birthdays': jsonEncode(seedList),
        });

        final birthdayService = BirthdayService(ApiService());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(birthdayService.upcomingThisMonth, equals(1));
        expect(birthdayService.pastBirthdays.length, equals(1));
        expect(birthdayService.pastBirthdays.first.id, equals(201));
      }
    });
  });
}
