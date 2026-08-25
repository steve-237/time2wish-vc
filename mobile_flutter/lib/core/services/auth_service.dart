import 'package:flutter/material.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final int coins;
  final String planType;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.coins,
    required this.planType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 1,
      email: json['email'] ?? 'demo@time2wish.app',
      fullName: json['fullName'] ?? json['username'] ?? json['email'] ?? 'Utilisateur Autonome',
      coins: json['coins'] ?? json['wishCoins'] ?? 100,
      planType: json['planType'] ?? 'PREMIUM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'coins': coins,
      'planType': planType,
    };
  }
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  final LocalStorageService _storageService = LocalStorageService();
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  AuthService(this._apiService) {
    checkInitialAuth();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _apiService.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await _apiService.dio.get('/auth/me');
        if (response.statusCode == 200 && response.data != null) {
          _currentUser = UserModel.fromJson(response.data);
          _isAuthenticated = true;
          await _storageService.saveProfile(_currentUser!.toJson());
          return;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] API offline/unreachable: $e');
    }

    // Offline mode: load from LocalStorageService or default local user profile
    final storedProfile = await _storageService.loadProfile();
    if (storedProfile != null) {
      _currentUser = UserModel.fromJson(storedProfile);
    } else {
      _currentUser = UserModel(
        id: 1,
        email: 'mon.compte@time2wish.local',
        fullName: 'Utilisateur Autonome',
        coins: 100,
        planType: 'PREMIUM',
      );
      await _storageService.saveProfile(_currentUser!.toJson());
    }
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final String token = response.data['accessToken'] ?? response.data['token'] ?? 'demo_token';
        await _apiService.saveToken(token);
        if (response.data['user'] != null) {
          _currentUser = UserModel.fromJson(response.data['user']);
        } else {
          _currentUser = UserModel(
            id: 1,
            email: email,
            fullName: email.split('@')[0],
            coins: 100,
            planType: 'PREMIUM',
          );
        }
        await _storageService.saveProfile(_currentUser!.toJson());
        _isAuthenticated = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Offline login fallback.');
      await _apiService.saveToken('offline_jwt_token_123');
      _currentUser = UserModel(
        id: 1,
        email: email.isNotEmpty ? email : 'mon.compte@time2wish.local',
        fullName: email.contains('@') ? email.split('@')[0] : 'Utilisateur Autonome',
        coins: 100,
        planType: 'PREMIUM',
      );
      await _storageService.saveProfile(_currentUser!.toJson());
      _isAuthenticated = true;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    return await login(email, password);
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
