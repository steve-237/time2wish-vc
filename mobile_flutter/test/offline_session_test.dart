import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/birthday_model.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';
import 'package:time2wish_mobile/core/services/auth_service.dart';
import 'package:time2wish_mobile/core/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Multi-Account & Scoped Storage Tests', () {
    late LocalStorageService storage;
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService();
      authService = AuthService(ApiService());
    });

    tearDown(() {
      authService.dispose();
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
        id: 1,
        name: 'Ami de Thomas',
        birthdate: DateTime(1995, 5, 10),
      );

      final user2Birthday = BirthdayModel(
        id: 2,
        name: 'Ami de Marie',
        birthdate: DateTime(1998, 8, 20),
      );

      // Save for user 1001
      await storage.saveBirthdays([user1Birthday], userId: 1001);

      // Save for user 1002
      await storage.saveBirthdays([user2Birthday], userId: 1002);

      // Load for user 1001
      final list1 = await storage.loadBirthdays(userId: 1001);
      expect(list1.length, equals(1));
      expect(list1.first.name, equals('Ami de Thomas'));

      // Load for user 1002
      final list2 = await storage.loadBirthdays(userId: 1002);
      expect(list2.length, equals(1));
      expect(list2.first.name, equals('Ami de Marie'));
    });

    test('A newly created offline user starts with an empty birthday list', () async {
      final list = await storage.loadBirthdays(userId: 2000);
      expect(list, isEmpty);
    });

    test('Reset offline security code (PIN) allows recovery when credentials are forgotten (#86)', () async {
      // 1. Create offline account with initial PIN '1111'
      final createResult = await authService.loginOffline(
        username: 'Alice Wonderland',
        securityCode: '1111',
      );
      expect(createResult, equals(OfflineAuthResult.success));

      await authService.logout();

      // 2. Try logging in with wrong PIN '9999' -> rejected
      final wrongLogin = await authService.loginOffline(
        username: 'Alice Wonderland',
        securityCode: '9999',
      );
      expect(wrongLogin, equals(OfflineAuthResult.invalidPin));

      // 3. Reset PIN to '2222'
      final resetSuccess = await authService.resetOfflineSecurityCode(
        username: 'Alice Wonderland',
        newSecurityCode: '2222',
      );
      expect(resetSuccess, isTrue);

      // 4. Verify old PIN '1111' is no longer accepted
      final oldPinLogin = await authService.loginOffline(
        username: 'Alice Wonderland',
        securityCode: '1111',
      );
      expect(oldPinLogin, equals(OfflineAuthResult.invalidPin));

      // 5. Verify new PIN '2222' succeeds
      final newPinLogin = await authService.loginOffline(
        username: 'Alice Wonderland',
        securityCode: '2222',
      );
      expect(newPinLogin, equals(OfflineAuthResult.success));

      // 6. Reset for unknown username fails
      final failReset = await authService.resetOfflineSecurityCode(
        username: 'NonExistentUser',
        newSecurityCode: '0000',
      );
      expect(failReset, isFalse);
    });
  });
}
