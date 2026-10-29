import 'package:flutter/material.dart';
import '../models/fundraiser_model.dart';
import 'api_service.dart';

class FundraiserService extends ChangeNotifier {
  final ApiService _apiService;
  final Map<int, FundraiserModel> _cacheByGiftId = {};

  FundraiserService(this._apiService);

  FundraiserModel? getCached(int giftId) => _cacheByGiftId[giftId];

  /// Get or initialize a collective fundraiser for a gift
  Future<FundraiserModel> getOrCreateFundraiser(int giftId, {double? defaultTarget}) async {
    final target = defaultTarget ?? 100.0;

    try {
      final response = await _apiService.dio.get(
        '/fundraisers/gift/$giftId',
        queryParameters: {'target': target},
      );

      if (response.statusCode == 200 && response.data != null) {
        final model = FundraiserModel.fromJson(response.data);
        _cacheByGiftId[giftId] = model;
        notifyListeners();
        return model;
      }
    } catch (e) {
      debugPrint('[FundraiserService] API offline, using local cached/demo fundraiser: $e');
    }

    // Local fallback
    if (!_cacheByGiftId.containsKey(giftId)) {
      _cacheByGiftId[giftId] = FundraiserModel(
        id: giftId * 10,
        giftId: giftId,
        targetAmount: target,
        currentAmount: target * 0.45,
        remainingAmount: target * 0.55,
        isCompleted: false,
        currency: 'EUR',
        active: true,
        pledges: [
          PledgeModel(
            id: 1,
            contributorName: 'Sophie',
            amount: 25.0,
            message: 'Joyeux anniversaire ! Gros bisous ❤️',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          PledgeModel(
            id: 2,
            contributorName: 'Lucas',
            amount: 20.0,
            message: 'Pour le super cadeau groupé ! 🎉',
            createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
        ],
      );
    }

    notifyListeners();
    return _cacheByGiftId[giftId]!;
  }

  /// Add a pledge / contribution to a fundraiser
  Future<FundraiserModel?> addPledge(
    int fundraiserId,
    int giftId,
    double amount, {
    String? contributorName,
    String? message,
  }) async {
    final name = contributorName ?? 'Vous';

    try {
      final response = await _apiService.dio.post(
        '/fundraisers/$fundraiserId/pledges',
        data: {
          'amount': amount,
          'guestName': name,
          'message': message,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final updated = FundraiserModel.fromJson(response.data);
        _cacheByGiftId[giftId] = updated;
        notifyListeners();
        return updated;
      }
    } catch (e) {
      debugPrint('[FundraiserService] API offline contribution fallback: $e');
    }

    // Optimistic / local fallback update
    final current = _cacheByGiftId[giftId];
    if (current != null) {
      final newCurrent = current.currentAmount + amount;
      final newRemaining = (current.targetAmount - newCurrent) > 0
          ? (current.targetAmount - newCurrent)
          : 0.0;
      final updatedPledges = List<PledgeModel>.from(current.pledges)
        ..insert(
          0,
          PledgeModel(
            id: DateTime.now().millisecondsSinceEpoch,
            contributorName: name,
            amount: amount,
            message: message,
            createdAt: DateTime.now(),
          ),
        );

      final updated = current.copyWith(
        currentAmount: newCurrent,
        remainingAmount: newRemaining,
        isCompleted: newCurrent >= current.targetAmount,
        pledges: updatedPledges,
      );

      _cacheByGiftId[giftId] = updated;
      notifyListeners();
      return updated;
    }

    return null;
  }
}
