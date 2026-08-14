import 'package:flutter/material.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';

class BirthdayService extends ChangeNotifier {
  final ApiService _apiService;
  List<BirthdayModel> _birthdays = [];
  bool _isLoading = false;
  String? _error;

  BirthdayService(this._apiService);

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
      return nextBd.month == now.month && nextBd.year == now.year;
    }).length;
  }

  /// Fetch all birthdays from API or use demo data
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
      }
    } catch (e) {
      debugPrint('[BirthdayService] API offline, loading demo data: $e');
      _birthdays = _getDemoBirthdays();
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

  /// Create a new birthday
  Future<BirthdayModel?> createBirthday(BirthdayModel birthday) async {
    try {
      final response = await _apiService.dio.post(
        '/birthdays',
        data: birthday.toJson(),
      );
      if (response.statusCode == 201 && response.data != null) {
        final created = BirthdayModel.fromJson(response.data);
        _birthdays.add(created);
        notifyListeners();
        return created;
      }
    } catch (e) {
      debugPrint('[BirthdayService] API offline, creating locally: $e');
      final localBirthday = birthday.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        createdAt: DateTime.now(),
      );
      _birthdays.add(localBirthday);
      notifyListeners();
      return localBirthday;
    }
    return null;
  }

  /// Update an existing birthday
  Future<BirthdayModel?> updateBirthday(int id, BirthdayModel birthday) async {
    try {
      final response = await _apiService.dio.put(
        '/birthdays/$id',
        data: birthday.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final updated = BirthdayModel.fromJson(response.data);
        final index = _birthdays.indexWhere((b) => b.id == id);
        if (index != -1) {
          _birthdays[index] = updated;
          notifyListeners();
        }
        return updated;
      }
    } catch (e) {
      debugPrint('[BirthdayService] API offline, updating locally: $e');
      final index = _birthdays.indexWhere((b) => b.id == id);
      if (index != -1) {
        _birthdays[index] = birthday.copyWith(id: id);
        notifyListeners();
        return _birthdays[index];
      }
    }
    return null;
  }

  /// Delete a birthday
  Future<bool> deleteBirthday(int id) async {
    try {
      final response = await _apiService.dio.delete('/birthdays/$id');
      if (response.statusCode == 200) {
        _birthdays.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[BirthdayService] API offline, deleting locally: $e');
      _birthdays.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Demo data for offline mode
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
        notes: 'Collègue préférée, aime les livres',
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
        notes: 'Organiser une fête surprise! 🎉',
        interests: ['Football', 'Photographie'],
        isFavorite: true,
        partyLocation: 'Chez Sophie',
        partyDescription: 'Fête surprise pour ses 33 ans',
        reminderDays: 7,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      BirthdayModel(
        id: 5,
        name: 'Camille Petit',
        birthdate: DateTime(1998, now.month + 2, 8),
        category: 'FAMILLE',
        gender: 'F',
        interests: ['Danse', 'Mode', 'Art'],
        isFavorite: false,
        reminderDays: 3,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }
}
