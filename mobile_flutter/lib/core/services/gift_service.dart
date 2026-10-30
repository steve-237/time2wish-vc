import 'package:flutter/material.dart';
import '../models/gift_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';

class GiftService extends ChangeNotifier {
  final ApiService _apiService;
  final SyncService? _syncService;
  final LocalStorageService _storageService = LocalStorageService();
  Map<int, List<GiftModel>> _giftsCache = {};
  bool _isLoading = false;

  GiftService(this._apiService, [this._syncService]) {
    _initLocalStorage();
  }

  bool get isLoading => _isLoading;

  Future<void> _initLocalStorage() async {
    _giftsCache = await _storageService.loadGifts();
    notifyListeners();
  }

  List<GiftModel> getGiftsForBirthday(int birthdayId) {
    return _giftsCache[birthdayId] ?? [];
  }

  Future<void> fetchGifts(int birthdayId) async {
    _isLoading = true;
    notifyListeners();

    final sync = _syncService;
    if (sync != null && sync.hasPending) {
      await sync.syncAll();
    }

    try {
      final response = await _apiService.dio.get('/birthdays/$birthdayId/gifts');
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data as List)
            .map((json) => GiftModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _giftsCache[birthdayId] = list;
        await _storageService.saveGifts(_giftsCache);
      }
    } catch (e) {
      debugPrint('[GiftService] Offline/fallback gift fetch: $e');
      final loaded = await _storageService.loadGifts();
      if (loaded.containsKey(birthdayId)) {
        _giftsCache[birthdayId] = loaded[birthdayId]!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<GiftModel?> addGift(
    int birthdayId,
    String name,
    String? description,
    String? priceRange, {
    String? url,
  }) async {
    final provisionalGift = GiftModel(
      id: DateTime.now().millisecondsSinceEpoch,
      birthdayId: birthdayId,
      name: name,
      description: description,
      priceRange: priceRange,
      url: url,
    );

    if (!_giftsCache.containsKey(birthdayId)) {
      _giftsCache[birthdayId] = [];
    }
    _giftsCache[birthdayId]!.add(provisionalGift);
    await _storageService.saveGifts(_giftsCache);
    notifyListeners();

    final payload = {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (priceRange != null && priceRange.isNotEmpty) 'priceRange': priceRange,
      if (url != null && url.isNotEmpty) 'url': url,
    };

    try {
      final response = await _apiService.dio.post(
        '/birthdays/$birthdayId/gifts',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        final serverGift = GiftModel.fromJson(response.data as Map<String, dynamic>);
        final list = _giftsCache[birthdayId];
        if (list != null) {
          final idx = list.indexWhere((g) => g.id == provisionalGift.id);
          if (idx != -1) {
            list[idx] = serverGift;
          }
        }
        await _storageService.saveGifts(_giftsCache);
        notifyListeners();
        return serverGift;
      }
    } catch (e) {
      debugPrint('[GiftService] Offline add gift queued: $e');
      await _syncService?.enqueue(
        endpoint: '/birthdays/$birthdayId/gifts',
        method: 'POST',
        data: payload,
      );
    }
    return provisionalGift;
  }

  Future<void> toggleReserveGift(int birthdayId, int giftId, String userName) async {
    final list = _giftsCache[birthdayId];
    if (list == null) return;
    final index = list.indexWhere((g) => g.id == giftId);
    if (index == -1) return;

    final current = list[index];
    final bool nextReserved = !current.isReserved;
    final String? nextReservedByName = nextReserved ? (userName.isNotEmpty ? userName : 'Vous') : null;

    final updatedGift = current.copyWith(
      isReserved: nextReserved,
      reservedByName: nextReservedByName,
    );
    list[index] = updatedGift;
    _giftsCache[birthdayId] = list;
    await _storageService.saveGifts(_giftsCache);
    notifyListeners();

    try {
      final response = await _apiService.dio.put(
        '/birthdays/$birthdayId/gifts/$giftId/reserve',
        data: {'guestName': userName},
      );
      if (response.statusCode == 200 && response.data != null) {
        final serverGift = GiftModel.fromJson(response.data as Map<String, dynamic>);
        final currentList = _giftsCache[birthdayId];
        if (currentList != null) {
          final curIdx = currentList.indexWhere((g) => g.id == giftId);
          if (curIdx != -1) {
            currentList[curIdx] = serverGift;
            _giftsCache[birthdayId] = currentList;
            await _storageService.saveGifts(_giftsCache);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[GiftService] Offline toggle reserve queued: $e');
      await _syncService?.enqueue(
        endpoint: '/birthdays/$birthdayId/gifts/$giftId/reserve',
        method: 'PUT',
        data: {'guestName': userName},
      );
    }
  }

  Future<void> deleteGift(int birthdayId, int giftId) async {
    final list = _giftsCache[birthdayId];
    if (list != null) {
      list.removeWhere((g) => g.id == giftId);
      _giftsCache[birthdayId] = list;
      await _storageService.saveGifts(_giftsCache);
      notifyListeners();
    }

    try {
      await _apiService.dio.delete('/birthdays/$birthdayId/gifts/$giftId');
    } catch (e) {
      debugPrint('[GiftService] Offline delete gift queued: $e');
      await _syncService?.enqueue(
        endpoint: '/birthdays/$birthdayId/gifts/$giftId',
        method: 'DELETE',
      );
    }
  }
}
