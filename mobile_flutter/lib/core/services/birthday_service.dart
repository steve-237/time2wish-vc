import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'sync_service.dart';
import 'notification_service.dart';

class BirthdayService extends ChangeNotifier {
  final ApiService _apiService;
  final SyncService? _syncService;
  final LocalStorageService _storageService = LocalStorageService();
  List<BirthdayModel> _birthdays = [];
  bool _isLoading = false;
  String? _error;

  BirthdayService(this._apiService, [this._syncService]) {
    _initLocalStorage();
  }

  List<BirthdayModel> get birthdays => _birthdays;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SyncService? get syncService => _syncService;

  List<BirthdayModel> get upcoming {
    final sorted = List<BirthdayModel>.from(_birthdays);
    sorted.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return sorted;
  }

  int get upcomingThisMonth {
    final now = DateTime.now();
    return _birthdays.where((b) {
      return b.birthdate.month == now.month;
    }).length;
  }

  Future<void> _initLocalStorage() async {
    _birthdays = await _storageService.loadBirthdays();
    if (_birthdays.isEmpty) {
      _birthdays = _getDemoBirthdays();
      await _storageService.saveBirthdays(_birthdays);
    }
    for (final b in _birthdays) {
      await NotificationService.scheduleBirthdayReminder(b);
    }
    notifyListeners();
  }

  /// Fetch all birthdays from API if online, replay pending sync queue, or fallback to local storage
  Future<void> fetchBirthdays() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Replay offline mutations first if any exist
    final sync = _syncService;
    if (sync != null && sync.hasPending) {
      await sync.syncAll();
    }

    try {
      final response = await _apiService.dio.get('/birthdays');
      if (response.statusCode == 200 && response.data != null) {
        final serverList = (response.data as List)
            .map((json) => BirthdayModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Preserve any local birthdays that are pending synchronization
        final pendingIds = _syncService?.queue
            .where((m) => m.method == 'POST' && m.data != null)
            .map((m) => m.data!['id'])
            .toSet() ?? {};

        final pendingLocalItems = _birthdays.where((b) => pendingIds.contains(b.id)).toList();

        _birthdays = [...serverList, ...pendingLocalItems];
        await _storageService.saveBirthdays(_birthdays);
      }
    } catch (e) {
      debugPrint('[BirthdayService] Offline mode: loading local storage: $e');
      _birthdays = await _storageService.loadBirthdays();
      if (_birthdays.isEmpty) {
        _birthdays = _getDemoBirthdays();
        await _storageService.saveBirthdays(_birthdays);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get a single birthday by ID
  BirthdayModel? getBirthdayById(int id) {
    try {
      return _birthdays.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new birthday with local persistence and offline sync queue
  Future<BirthdayModel?> createBirthday(BirthdayModel birthday) async {
    final newId = birthday.id != 0 ? birthday.id : DateTime.now().millisecondsSinceEpoch;
    final created = birthday.copyWith(
      id: newId,
      createdAt: DateTime.now(),
    );

    _birthdays.add(created);
    await _storageService.saveBirthdays(_birthdays);
    await NotificationService.scheduleBirthdayReminder(created);
    notifyListeners();

    try {
      final response = await _apiService.dio.post(
        '/birthdays',
        data: created.toApiJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final serverBirthday = BirthdayModel.fromJson(response.data as Map<String, dynamic>);
        final idx = _birthdays.indexWhere((b) => b.id == created.id);
        if (idx != -1) {
          _birthdays[idx] = serverBirthday;
          await _storageService.saveBirthdays(_birthdays);
          notifyListeners();
          return serverBirthday;
        }
      }
    } catch (e) {
      debugPrint('[BirthdayService] Offline create: saved locally and queued for sync: $e');
      await _syncService?.enqueue(
        endpoint: '/birthdays',
        method: 'POST',
        data: created.toApiJson(),
      );
    }
    return created;
  }

  /// Update an existing birthday with local persistence and offline sync queue
  Future<BirthdayModel?> updateBirthday(int id, BirthdayModel birthday) async {
    final index = _birthdays.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = birthday.copyWith(id: id);
      _birthdays[index] = updated;
      await _storageService.saveBirthdays(_birthdays);
      await NotificationService.scheduleBirthdayReminder(updated);
      notifyListeners();

      try {
        final response = await _apiService.dio.put(
          '/birthdays/$id',
          data: updated.toApiJson(),
        );
        if (response.statusCode == 200 && response.data != null) {
          final serverBirthday = BirthdayModel.fromJson(response.data as Map<String, dynamic>);
          final idx = _birthdays.indexWhere((b) => b.id == id);
          if (idx != -1) {
            _birthdays[idx] = serverBirthday;
            await _storageService.saveBirthdays(_birthdays);
            notifyListeners();
            return serverBirthday;
          }
        }
      } catch (e) {
        debugPrint('[BirthdayService] Offline update: saved locally and queued for sync: $e');
        await _syncService?.enqueue(
          endpoint: '/birthdays/$id',
          method: 'PUT',
          data: updated.toApiJson(),
        );
      }
      return updated;
    }
    return null;
  }

  /// Delete a birthday with local persistence and offline sync queue
  Future<bool> deleteBirthday(int id) async {
    _birthdays.removeWhere((b) => b.id == id);
    await _storageService.saveBirthdays(_birthdays);
    await NotificationService.cancelBirthdayReminder(id);
    notifyListeners();

    try {
      await _apiService.dio.delete('/birthdays/$id');
    } catch (e) {
      debugPrint('[BirthdayService] Offline delete: removed locally and queued for sync: $e');
      await _syncService?.enqueue(
        endpoint: '/birthdays/$id',
        method: 'DELETE',
      );
    }
    return true;
  }

  /// Toggle favorite status locally
  Future<void> toggleFavorite(int id) async {
    final index = _birthdays.indexWhere((b) => b.id == id);
    if (index != -1) {
      _birthdays[index] = _birthdays[index].copyWith(
        isFavorite: !_birthdays[index].isFavorite,
      );
      await _storageService.saveBirthdays(_birthdays);
      notifyListeners();
    }
  }

  /// Export all current birthdays to a clean formatted JSON string
  String exportToJson() {
    final exportData = {
      'app': 'Time2Wish',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalCount': _birthdays.length,
      'birthdays': _birthdays.map((b) => b.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Import birthdays from a JSON string (either direct list or wrapped object)
  /// Returns the count of successfully imported birthdays
  Future<int> importFromJson(String jsonContent, {bool replaceExisting = false}) async {
    try {
      final dynamic decoded = jsonDecode(jsonContent.trim());
      List<dynamic> rawList;

      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['birthdays'] is List) {
        rawList = decoded['birthdays'] as List<dynamic>;
      } else {
        throw const FormatException('Format JSON non reconnu. Une liste d\'anniversaires est attendue.');
      }

      final List<BirthdayModel> imported = [];
      int baseId = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is Map<String, dynamic>) {
          final name = (item['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) continue;

          DateTime? birthdate;
          if (item['birthdate'] != null) {
            birthdate = DateTime.tryParse(item['birthdate'].toString());
          }
          if (birthdate == null) continue;

          final model = BirthdayModel(
            id: (item['id'] is int && (item['id'] as int) > 0)
                ? item['id'] as int
                : (baseId + i),
            name: name,
            birthdate: birthdate,
            category: (item['category'] as String?) ?? 'AUTRE',
            gender: item['gender'] as String?,
            notes: item['notes'] as String?,
            interests: (item['interests'] is List)
                ? (item['interests'] as List).map((e) => e.toString()).toList()
                : [],
            reminderDays: (item['reminderDays'] as int?) ?? 3,
            isFavorite: (item['isFavorite'] as bool?) ?? false,
            partyLocation: item['partyLocation'] as String?,
            partyDescription: item['partyDescription'] as String?,
            photoUrl: item['photoUrl'] as String?,
            createdAt: item['createdAt'] != null
                ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
                : DateTime.now(),
          );
          imported.add(model);
        }
      }

      if (imported.isEmpty) {
        return 0;
      }

      if (replaceExisting) {
        _birthdays = imported;
      } else {
        final existingIds = _birthdays.map((b) => b.id).toSet();
        for (final b in imported) {
          if (existingIds.contains(b.id)) {
            final idx = _birthdays.indexWhere((item) => item.id == b.id);
            _birthdays[idx] = b;
          } else {
            _birthdays.add(b);
            existingIds.add(b.id);
          }
        }
      }

      await _storageService.saveBirthdays(_birthdays);
      for (final b in imported) {
        await NotificationService.scheduleBirthdayReminder(b);
      }
      notifyListeners();
      return imported.length;
    } catch (e) {
      debugPrint('[BirthdayService] Error importing birthdays from JSON: $e');
      rethrow;
    }
  }

  /// Demo seed data for first initialization
  List<BirthdayModel> _getDemoBirthdays() {
    final now = DateTime.now();
    return [
      BirthdayModel(
        id: 1,
        name: 'Sophie Martin',
        birthdate: DateTime(1995, now.month, now.day + 3),
        category: 'AMIS',
        gender: 'F',
        notes: 'Adore le chocolat et les fleurs 🌸',
        interests: ['Musique', 'Voyage', 'Cuisine'],
        isFavorite: true,
        reminderDays: 3,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      BirthdayModel(
        id: 2,
        name: 'Alexandre Dubois',
        birthdate: DateTime(1988, now.month, now.day + 12),
        category: 'FAMILLE',
        gender: 'M',
        notes: 'Fan de tech et de jeux vidéo 🎮',
        interests: ['Gaming', 'Tech', 'Sport'],
        isFavorite: false,
        reminderDays: 7,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      BirthdayModel(
        id: 3,
        name: 'Emma Leroy',
        birthdate: DateTime(2000, now.month + 1, 15),
        category: 'TRAVAIL',
        gender: 'F',
        notes: 'Collègue préférée, aime les livres 📚',
        interests: ['Lecture', 'Yoga', 'Cinéma'],
        isFavorite: false,
        reminderDays: 5,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      BirthdayModel(
        id: 4,
        name: 'Lucas Bernard',
        birthdate: DateTime(1992, now.month + 1, 28),
        category: 'AMIS',
        gender: 'M',
        notes: 'Organiser une fête surprise ! 🎉',
        interests: ['Football', 'Photographie'],
        isFavorite: true,
        partyLocation: 'Chez Sophie',
        partyDescription: 'Fête surprise pour ses 33 ans',
        reminderDays: 7,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
    ];
  }
}
