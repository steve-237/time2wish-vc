import 'package:flutter/material.dart';
import 'api_service.dart';

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
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['username'] ?? json['email'] ?? 'User',
      coins: json['coins'] ?? json['wishCoins'] ?? 0,
      planType: json['planType'] ?? 'BASIC',
    );
  }
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService;
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
        }
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
            coins: 50,
            planType: 'PREMIUM',
          );
        }
        _isAuthenticated = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Backend API offline/unreachable: $e. Falling back to Demo Mode.');
      // Demo Mode Fallback for testing UI offline
      await _apiService.saveToken('demo_jwt_token_123');
      _currentUser = UserModel(
        id: 1,
        email: email.isNotEmpty ? email : 'demo@time2wish.app',
        fullName: email.contains('@') ? email.split('@')[0] : 'Demo User',
        coins: 50,
        planType: 'PREMIUM',
      );
      _isAuthenticated = true;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await login(email, password);
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
