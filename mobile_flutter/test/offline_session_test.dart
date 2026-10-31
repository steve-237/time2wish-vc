import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/local_storage_service.dart';
import 'package:time2wish_mobile/features/birthdays/domain/birthday_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Multi-Account & Scoped Storage Tests', () {
    late LocalStorageService storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService();
    });

    test('Initial active offline account is null', () async {
      final activeId = await storage.getActiveOfflineAccountId();
      expect(activeId, isNull);
    });

    test('Save offline account and retrieve by username and id', () async {
      final accountData = {
        'id': 1001,
        'name': 'Thomas',
        'email': 'thomas@offline.local',
        'securityCode': '1234',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await storage.saveOfflineAccount(accountData);
      await storage.setActiveOfflineAccountId(1001);

      final activeId = await storage.getActiveOfflineAccountId();
      expect(activeId, equals(1001));

      final byName = await storage.getOfflineAccountByUsername('Thomas');
      expect(byName, isNotNull);
      expect(byName!['id'], equals(1001));
      expect(byName['securityCode'], equals('1234'));

      // Case insensitive match
      final byNameLower = await storage.getOfflineAccountByUsername('thomas');
      expect(byNameLower, isNotNull);
      expect(byNameLower!['name'], equals('Thomas'));

      final byId = await storage.getOfflineAccountById(1001);
      expect(byId, isNotNull);
      expect(byId!['name'], equals('Thomas'));
    });

    test('Clear active offline session', () async {
      await storage.setActiveOfflineAccountId(1002);
      expect(await storage.getActiveOfflineAccountId(), equals(1002));

      await storage.clearActiveOfflineSession();
      expect(await storage.getActiveOfflineAccountId(), isNull);
    });

    test('Birthdays are isolated between user accounts', () async {
      final user1Birthday = BirthdayModel(
        id: 'b1',
        fullName: 'Ami de Thomas',
        dateOfBirth: DateTime(1995, 5, 10),
      );

      final user2Birthday = BirthdayModel(
        id: 'b2',
        fullName: 'Ami de Marie',
        dateOfBirth: DateTime(1998, 8, 20),
      );

      // Save for user 1001
      await storage.saveBirthdays([user1Birthday], userId: 1001);

      // Save for user 1002
      await storage.saveBirthdays([user2Birthday], userId: 1002);

      // Load for user 1001
      final list1 = await storage.loadBirthdays(userId: 1001);
      expect(list1.length, equals(1));
      expect(list1.first.fullName, equals('Ami de Thomas'));

      // Load for user 1002
      final list2 = await storage.loadBirthdays(userId: 1002);
      expect(list2.length, equals(1));
      expect(list2.first.fullName, equals('Ami de Marie'));
    });
  });
}
