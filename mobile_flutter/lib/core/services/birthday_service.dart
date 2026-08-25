import 'package:flutter/material.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class BirthdayService extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storageService = LocalStorageService();
  List<BirthdayModel> _birthdays = [];
  bool _isLoading = false;
  String? _error;

  BirthdayService(this._apiService) {
    _initLocalStorage();
  }

  List<BirthdayModel> get birthdays => _birthdays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BirthdayModel> get upcoming {
    final sorted = List<BirthdayModel>.from(_birthdays);
    sorted.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return sorted;
  }

  int get upcomingThisMonth {
    final now = DateTime.now();
    return _birthdays.where((b) {
      final nextBd = DateTime(now.year, b.birthdate.month, b.birthdate.day);
      return nextBd.month == now.month;
    }).length;
  }

  Future<void> _initLocalStorage() async {
    _birthdays = await _storageService.loadBirthdays();
    if (_birthdays.isEmpty) {
      _birthdays = _getDemoBirthdays();
      await _storageService.saveBirthdays(_birthdays);
    }
    notifyListeners();
  }

  /// Fetch all birthdays from API if online, or fallback to local storage
  Future<void> fetchBirthdays() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/birthdays');
      if (response.statusCode == 200 && response.data != null) {
        _birthdays = (response.data as List)
            .map((json) => BirthdayModel.fromJson(json))
            .toList();
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

  /// Create a new birthday with local persistence
  Future<BirthdayModel?> createBirthday(BirthdayModel birthday) async {
    final newId = birthday.id != 0 ? birthday.id : DateTime.now().millisecondsSinceEpoch;
    final created = birthday.copyWith(
      id: newId,
      createdAt: DateTime.now(),
    );

    _birthdays.add(created);
    await _storageService.saveBirthdays(_birthdays);
    notifyListeners();

    try {
      await _apiService.dio.post(
        '/birthdays',
        data: created.toJson(),
      );
    } catch (e) {
      debugPrint('[BirthdayService] Offline create: saved locally: $e');
    }
    return created;
  }

  /// Update an existing birthday with local persistence
  Future<BirthdayModel?> updateBirthday(int id, BirthdayModel birthday) async {
    final index = _birthdays.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = birthday.copyWith(id: id);
      _birthdays[index] = updated;
      await _storageService.saveBirthdays(_birthdays);
      notifyListeners();

      try {
        await _apiService.dio.put(
          '/birthdays/$id',
          data: updated.toJson(),
        );
      } catch (e) {
        debugPrint('[BirthdayService] Offline update: saved locally: $e');
      }
      return updated;
    }
    return null;
  }

  /// Delete a birthday with local persistence
  Future<bool> deleteBirthday(int id) async {
    _birthdays.removeWhere((b) => b.id == id);
    await _storageService.saveBirthdays(_birthdays);
    notifyListeners();

    try {
      await _apiService.dio.delete('/birthdays/$id');
    } catch (e) {
      debugPrint('[BirthdayService] Offline delete: removed locally: $e');
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
