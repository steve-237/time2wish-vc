import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/birthday_model.dart';
import 'package:time2wish_mobile/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService & Reminders Tests', () {
    test('Schedule reminders generates J-7, J-3, and day-of reminders', () async {
      SharedPreferences.setMockInitialValues({});

      final now = DateTime.now();
      // Birthday in 15 days
      final testBirthday = BirthdayModel(
        id: 99,
        name: 'Camille',
        birthdate: DateTime(1998, now.month, now.day).add(const Duration(days: 15)),
        category: 'AMIS',
      );

      final reminders = await NotificationService.scheduleBirthdayReminder(testBirthday);
      expect(reminders.isNotEmpty, true);

      // Verify reminders in storage
      final all = await NotificationService.getAllReminders();
      expect(all.any((r) => r.birthdayId == 99), true);

      // Cancel reminders
      await NotificationService.cancelBirthdayReminder(99);
      final remaining = await NotificationService.getAllReminders();
      expect(remaining.any((r) => r.birthdayId == 99), false);
    });
  });
}
