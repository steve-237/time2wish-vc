import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/gift_model.dart';
import 'package:time2wish_mobile/core/services/gift_service.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GiftModel & GiftService Selector Tests', () {
    test('GiftModel.fromJson assigns unique id when raw id is missing or zero', () {
      final jsonNoId = {'name': 'Livre de cuisine', 'birthdayId': 1};
      final gift1 = GiftModel.fromJson(jsonNoId, 101);
      final gift2 = GiftModel.fromJson(jsonNoId, 102);

      expect(gift1.id, 101);
      expect(gift2.id, 102);
      expect(gift1.id != gift2.id, isTrue);
    });

    test('GiftService toggles specific gift by id and fallbackIndex accurately', () async {
      SharedPreferences.setMockInitialValues({});
      final apiService = ApiService();
      final giftService = GiftService(apiService);

      // Add 3 gifts for birthday 99
      final g1 = await giftService.addGift(99, 'Cadeau 1', 'Desc 1', '20€');
      final g2 = await giftService.addGift(99, 'Cadeau 2', 'Desc 2', '30€');
      final g3 = await giftService.addGift(99, 'Cadeau 3', 'Desc 3', '40€');

      final initialList = giftService.getGiftsForBirthday(99);
      expect(initialList.length, 3);
      expect(initialList[0].isReserved, isFalse);
      expect(initialList[1].isReserved, isFalse);
      expect(initialList[2].isReserved, isFalse);

      // Reserve ONLY gift #2 (index 1)
      await giftService.toggleReserveGift(99, g2.id, 'Alice', fallbackIndex: 1);

      final updatedList = giftService.getGiftsForBirthday(99);
      expect(updatedList[0].isReserved, isFalse, reason: 'Gift 1 should remain unreserved');
      expect(updatedList[1].isReserved, isTrue, reason: 'Gift 2 must be reserved');
      expect(updatedList[1].reservedByName, 'Alice');
      expect(updatedList[2].isReserved, isFalse, reason: 'Gift 3 should remain unreserved');

      // Release gift #2
      await giftService.toggleReserveGift(99, g2.id, 'Alice', fallbackIndex: 1);
      final releasedList = giftService.getGiftsForBirthday(99);
      expect(releasedList[1].isReserved, isFalse, reason: 'Gift 2 must now be released');
    });

    test('GiftService deleteGift with fallbackIndex deletes the correct item', () async {
      SharedPreferences.setMockInitialValues({});
      final apiService = ApiService();
      final giftService = GiftService(apiService);

      final g1 = await giftService.addGift(88, 'A', 'Desc A', '10€');
      final g2 = await giftService.addGift(88, 'B', 'Desc B', '20€');
      final g3 = await giftService.addGift(88, 'C', 'Desc C', '30€');

      // Delete the middle gift (g2)
      await giftService.deleteGift(88, g2.id, fallbackIndex: 1);

      final list = giftService.getGiftsForBirthday(88);
      expect(list.length, 2);
      expect(list.any((g) => g.name == 'B'), isFalse);
      expect(list[0].name, 'A');
      expect(list[1].name, 'C');
    });
  });
}
