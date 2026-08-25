import 'package:flutter/material.dart';
import '../models/gift_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class GiftService extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storageService = LocalStorageService();
  Map<int, List<GiftModel>> _giftsCache = {};
  bool _isLoading = false;

  GiftService(this._apiService) {
    _initLocalStorage();
  }

  bool get isLoading => _isLoading;

  Future<void> _initLocalStorage() async {
    _giftsCache = await _storageService.loadGifts();
    notifyListeners();
  }

  List<GiftModel> getGiftsForBirthday(int birthdayId) {
    return _giftsCache[birthdayId] ?? _getDemoGifts(birthdayId);
  }

  Future<void> fetchGifts(int birthdayId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/birthdays/$birthdayId/gifts');
      if (response.statusCode == 200 && response.data != null) {
        _giftsCache[birthdayId] = (response.data as List)
            .map((json) => GiftModel.fromJson(json))
            .toList();
        await _storageService.saveGifts(_giftsCache);
      }
    } catch (e) {
      debugPrint('[GiftService] Offline mode gift fetch fallback: $e');
      final loaded = await _storageService.loadGifts();
      if (loaded.containsKey(birthdayId)) {
        _giftsCache[birthdayId] = loaded[birthdayId]!;
      } else if (!_giftsCache.containsKey(birthdayId)) {
        _giftsCache[birthdayId] = _getDemoGifts(birthdayId);
        await _storageService.saveGifts(_giftsCache);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GiftModel?> addGift(int birthdayId, String name, String? description, String? priceRange) async {
    final newGift = GiftModel(
      id: DateTime.now().millisecondsSinceEpoch,
      birthdayId: birthdayId,
      name: name,
      description: description,
      priceRange: priceRange,
    );

    if (!_giftsCache.containsKey(birthdayId)) {
      _giftsCache[birthdayId] = [];
    }
    _giftsCache[birthdayId]!.add(newGift);
    await _storageService.saveGifts(_giftsCache);
    notifyListeners();

    try {
      await _apiService.dio.post('/birthdays/$birthdayId/gifts', data: newGift.toJson());
    } catch (e) {
      debugPrint('[GiftService] Offline add gift saved locally');
    }
    return newGift;
  }

  Future<void> toggleReserveGift(int birthdayId, int giftId, String userName) async {
    final list = _giftsCache[birthdayId] ?? _getDemoGifts(birthdayId);
    final index = list.indexWhere((g) => g.id == giftId);
    if (index != -1) {
      final current = list[index];
      final isCurrentlyReserved = current.isReserved;
      list[index] = GiftModel(
        id: current.id,
        birthdayId: current.birthdayId,
        name: current.name,
        description: current.description,
        priceRange: current.priceRange,
        url: current.url,
        imageUrl: current.imageUrl,
        isReserved: !isCurrentlyReserved,
        reservedByName: !isCurrentlyReserved ? userName : null,
        upvotes: current.upvotes,
        downvotes: current.downvotes,
      );
      _giftsCache[birthdayId] = list;
      await _storageService.saveGifts(_giftsCache);
      notifyListeners();
    }
  }

  List<GiftModel> _getDemoGifts(int birthdayId) {
    return [
      GiftModel(
        id: 1,
        birthdayId: birthdayId,
        name: 'Casque Réduction de Bruit 🎧',
        description: 'Pour ses voyages et écouter de la musique au calme',
        priceRange: '150€ - 200€',
        isReserved: true,
        reservedByName: 'Sophie',
        upvotes: 5,
      ),
      GiftModel(
        id: 2,
        birthdayId: birthdayId,
        name: 'Coffret Dégustation Chocolat d\'Exception 🍫',
        description: 'Sélection artisanale grands crus',
        priceRange: '35€ - 50€',
        isReserved: false,
        upvotes: 3,
      ),
      GiftModel(
        id: 3,
        birthdayId: birthdayId,
        name: 'Smartwatch Sport & Santé ⌚',
        description: 'Suivi activité et rythme cardiaque',
        priceRange: '120€ - 180€',
        isReserved: false,
        upvotes: 2,
      ),
    ];
  }
}
