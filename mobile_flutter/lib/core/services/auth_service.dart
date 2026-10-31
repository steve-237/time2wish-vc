import 'package:flutter/material.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

enum OfflineAuthResult {
  success,
  created,
  invalidPin,
  emptyUsername,
  emptyPin,
}

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final int coins;
  final String planType;
  final String? avatarUrl;
  final String? bio;
  final String? securityCode;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.coins,
    required this.planType,
    this.avatarUrl,
    this.bio,
    this.securityCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      email: json['email'] ?? 'demo@time2wish.app',
      fullName: json['fullName'] ?? json['username'] ?? json['email'] ?? 'Utilisateur Autonome',
      coins: json['coins'] ?? json['wishCoins'] ?? 100,
      planType: json['planType'] ?? 'PREMIUM',
      avatarUrl: json['avatarUrl'] ?? json['avatar'] ?? json['photoUrl'],
      bio: json['bio'],
      securityCode: json['securityCode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'coins': coins,
      'planType': planType,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (bio != null) 'bio': bio,
      if (securityCode != null) 'securityCode': securityCode,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    int? coins,
    String? planType,
    String? avatarUrl,
    String? bio,
    String? securityCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      coins: coins ?? this.coins,
      planType: planType ?? this.planType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      securityCode: securityCode ?? this.securityCode,
    );
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
  bool get isOfflineMode =>
      _currentUser?.planType == 'OFFLINE_LOCAL' ||
      (_currentUser?.email.endsWith('.local') ?? false);

  Future<void> checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Check if an active offline session is saved
      final activeOfflineId = await _storageService.getActiveOfflineAccountId();
      if (activeOfflineId != null) {
        final offlineAcc = await _storageService.getOfflineAccountById(activeOfflineId);
        if (offlineAcc != null) {
          _currentUser = UserModel.fromJson(offlineAcc);
          _isAuthenticated = true;
          return;
        }
      }

      // 2. Check remote token if available
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

      // 3. Fallback: load legacy profile
      final storedProfile = await _storageService.loadProfile();
      if (storedProfile != null) {
        _currentUser = UserModel.fromJson(storedProfile);
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('[AuthService] API offline/unreachable: $e');
      final activeOfflineId = await _storageService.getActiveOfflineAccountId();
      if (activeOfflineId != null) {
        final offlineAcc = await _storageService.getOfflineAccountById(activeOfflineId);
        if (offlineAcc != null) {
          _currentUser = UserModel.fromJson(offlineAcc);
          _isAuthenticated = true;
          return;
        }
      }
      final storedProfile = await _storageService.loadProfile();
      if (storedProfile != null) {
        _currentUser = UserModel.fromJson(storedProfile);
        _isAuthenticated = true;
      }
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
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        return await login(email, password);
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Register offline/fallback: $e');
      _isLoading = false;
      return await login(email, password);
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Get list of all offline accounts created on this device
  Future<List<Map<String, dynamic>>> getSavedOfflineAccounts() async {
    final map = await _storageService.getOfflineAccounts();
    return map.values.toList();
  }

  /// Login or create a persistent offline user session protected by security code/PIN
  Future<OfflineAuthResult> loginOffline({
    required String username,
    required String securityCode,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanUsername = username.trim();
      final cleanPin = securityCode.trim();

      if (cleanUsername.isEmpty) return OfflineAuthResult.emptyUsername;
      if (cleanPin.isEmpty) return OfflineAuthResult.emptyPin;

      final existing = await _storageService.getOfflineAccountByUsername(cleanUsername);

      if (existing != null) {
        final storedPin = existing['securityCode']?.toString().trim() ?? '';
        if (storedPin.isNotEmpty && storedPin != cleanPin) {
          return OfflineAuthResult.invalidPin;
        }

        final updated = Map<String, dynamic>.from(existing);
        updated['lastLoginAt'] = DateTime.now().toIso8601String();
        // If account had no pin previously, save this pin
        if (storedPin.isEmpty) {
          updated['securityCode'] = cleanPin;
        }
        await _storageService.saveOfflineAccount(updated);
        await _storageService.setActiveOfflineAccountId(updated['id']);

        _currentUser = UserModel.fromJson(updated);
        _isAuthenticated = true;
        await _apiService.saveToken('offline_session_${updated['id']}');
        return OfflineAuthResult.success;
      } else {
        final newId = DateTime.now().millisecondsSinceEpoch;
        final cleanEmail = (email != null && email.trim().isNotEmpty)
            ? email.trim()
            : '${cleanUsername.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}@time2wish.local';

        final newAccount = {
          'id': newId,
          'username': cleanUsername,
          'fullName': cleanUsername,
          'email': cleanEmail,
          'securityCode': cleanPin,
          'coins': 100,
          'planType': 'OFFLINE_LOCAL',
          'createdAt': DateTime.now().toIso8601String(),
          'lastLoginAt': DateTime.now().toIso8601String(),
        };

        await _storageService.saveOfflineAccount(newAccount);
        await _storageService.setActiveOfflineAccountId(newId);

        _currentUser = UserModel.fromJson(newAccount);
        _isAuthenticated = true;
        await _apiService.saveToken('offline_session_$newId');
        return OfflineAuthResult.created;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile info (full name, avatar photo, bio) with local cache & optional remote sync
  Future<void> updateProfile({
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      fullName: (fullName != null && fullName.trim().isNotEmpty) ? fullName.trim() : _currentUser!.fullName,
      avatarUrl: avatarUrl,
      bio: bio,
    );

    await _storageService.saveProfile(_currentUser!.toJson());

    // Also update offline accounts map if in offline mode
    if (isOfflineMode) {
      await _storageService.saveOfflineAccount(_currentUser!.toJson());
    }

    notifyListeners();

    // Attempt remote update if backend is reachable
    try {
      await _apiService.dio.put('/users/profile', data: {
        'fullName': _currentUser!.fullName,
        'avatarUrl': _currentUser!.avatarUrl,
        'bio': _currentUser!.bio,
      });
    } catch (_) {
      // Offline fallback: saved locally
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    await _storageService.clearActiveOfflineSession();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
