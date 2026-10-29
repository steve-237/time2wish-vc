import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time2wish_mobile/core/models/fundraiser_model.dart';
import 'package:time2wish_mobile/core/services/api_service.dart';
import 'package:time2wish_mobile/core/services/fundraiser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FundraiserService Unit & Contribution Tests', () {
    late ApiService apiService;
    late FundraiserService fundraiserService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      apiService = ApiService();
      fundraiserService = FundraiserService(apiService);
    });

    tearDown(() {
      fundraiserService.dispose();
    });

    test('getOrCreateFundraiser returns initialized fundraiser with target and demo pledges', () async {
      final model = await fundraiserService.getOrCreateFundraiser(42, defaultTarget: 100.0);

      expect(model.giftId, equals(42));
      expect(model.targetAmount, equals(100.0));
      expect(model.pledges, isNotEmpty);
      expect(model.currentAmount, greaterThan(0));
      expect(fundraiserService.getCached(42), isNotNull);
    });

    test('progressPercentage calculates correct ratio and clamps at 1.0', () {
      final incomplete = FundraiserModel(
        id: 1,
        giftId: 1,
        targetAmount: 200.0,
        currentAmount: 50.0,
        remainingAmount: 150.0,
      );
      expect(incomplete.progressPercentage, equals(0.25));

      final completed = FundraiserModel(
        id: 2,
        giftId: 2,
        targetAmount: 100.0,
        currentAmount: 120.0,
        remainingAmount: 0.0,
        isCompleted: true,
      );
      expect(completed.progressPercentage, equals(1.0));
    });

    test('addPledge updates current amount, decreases remaining amount, and records pledge', () async {
      final initial = await fundraiserService.getOrCreateFundraiser(15, defaultTarget: 80.0);
      final initialCollected = initial.currentAmount;
      final initialPledgeCount = initial.pledges.length;

      final updated = await fundraiserService.addPledge(
        initial.id,
        15,
        25.0,
        contributorName: 'Alice',
        message: 'Bravo pour la fête !',
      );

      expect(updated, isNotNull);
      expect(updated!.currentAmount, equals(initialCollected + 25.0));
      expect(updated.pledges.length, equals(initialPledgeCount + 1));
      expect(updated.pledges.first.contributorName, equals('Alice'));
      expect(updated.pledges.first.amount, equals(25.0));
      expect(updated.pledges.first.message, equals('Bravo pour la fête !'));
    });

    test('FundraiserModel & PledgeModel JSON serialization roundtrip', () {
      final pledge = PledgeModel(
        id: 10,
        contributorName: 'Jean',
        amount: 30.0,
        message: 'Bon anniv !',
        createdAt: DateTime.parse('2026-10-30T10:00:00'),
      );
      final pledgeJson = pledge.toJson();
      final restoredPledge = PledgeModel.fromJson(pledgeJson);
      expect(restoredPledge.contributorName, equals('Jean'));
      expect(restoredPledge.amount, equals(30.0));

      final fundraiser = FundraiserModel(
        id: 99,
        giftId: 55,
        targetAmount: 150.0,
        currentAmount: 90.0,
        remainingAmount: 60.0,
        currency: 'EUR',
        active: true,
        pledges: [pledge],
      );

      final json = fundraiser.toJson();
      final restored = FundraiserModel.fromJson(json);
      expect(restored.targetAmount, equals(150.0));
      expect(restored.pledges.first.contributorName, equals('Jean'));
    });
  });
}
