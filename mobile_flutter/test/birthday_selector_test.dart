import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/services/birthday_service.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';
import 'package:time2wish_mobile/core/services/gift_service.dart';
import 'package:time2wish_mobile/core/services/device_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Birthday Selector & Details Consistency Tests', () {
    test('BirthdayService seeds Emma Leroy at ID 3 with correct details', () async {
      SharedPreferences.setMockInitialValues({});
      final apiService = ApiService();
      final birthdayService = BirthdayService(apiService);

      // Wait a microtask for _initLocalStorage
      await Future.delayed(const Duration(milliseconds: 50));

      final emma = birthdayService.getBirthdayById(3);
      expect(emma, isNotNull);
      expect(emma!.name, equals('Emma Leroy'));
      expect(emma.category, equals('TRAVAIL'));
      expect(emma.gender, equals('F'));
      expect(emma.interests, contains('Lecture'));
      expect(emma.interests, contains('Yoga'));
    });

    test('GiftService seeds distinct gift ideas for Emma Leroy (ID 3)', () async {
      SharedPreferences.setMockInitialValues({});
      final apiService = ApiService();
      final giftService = GiftService(apiService);

      await Future.delayed(const Duration(milliseconds: 50));

      final sophieGifts = giftService.getGiftsForBirthday(1);
      final emmaGifts = giftService.getGiftsForBirthday(3);

      expect(sophieGifts.isNotEmpty, isTrue);
      expect(emmaGifts.isNotEmpty, isTrue);
      expect(sophieGifts.first.name, isNot(equals(emmaGifts.first.name)));

      expect(emmaGifts.any((g) => g.name.contains('Alain Damasio')), isTrue);
      expect(emmaGifts.any((g) => g.name.contains('Yoga')), isTrue);
    });

    test('DeviceService audio and haptic triggers execute cleanly', () async {
      DeviceService.playTapSound();
      DeviceService.playSuccessSound();
      DeviceService.playCelebrationSound();
      await DeviceService.triggerLightHaptic();
      await DeviceService.triggerMediumHaptic();
      await DeviceService.triggerSuccessHaptic();
    });
  });
}
