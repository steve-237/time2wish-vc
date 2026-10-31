import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birthday_model.dart';
import '../models/gift_model.dart';
import '../models/contact_model.dart';

class LocalStorageService {
  static const _birthdaysKey = 't2w_local_birthdays';
  static const _giftsKey = 't2w_local_gifts';
  static const _contactsKey = 't2w_local_contacts';
  static const _profileKey = 't2w_local_profile';
  static const _offlineAccountsKey = 't2w_offline_accounts_map';
  static const _activeOfflineSessionKey = 't2w_active_offline_account_id';

  // --- Active Offline Session Management ---
  Future<int?> getActiveOfflineAccountId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_activeOfflineSessionKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> setActiveOfflineAccountId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeOfflineSessionKey, id);
    } catch (_) {}
  }

  Future<void> clearActiveOfflineSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeOfflineSessionKey);
    } catch (_) {}
  }

  // --- Multi-Account Offline Profiles ---
  Future<Map<String, Map<String, dynamic>>> getOfflineAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_offlineAccountsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = jsonDecode(jsonStr);
        final Map<String, Map<String, dynamic>> result = {};
        rawMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            result[key] = value;
          } else if (value is Map) {
            result[key] = Map<String, dynamic>.from(value);
          }
        });
        return result;
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading offline accounts: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>?> getOfflineAccountByUsername(String username) async {
    final accounts = await getOfflineAccounts();
    final normalized = username.trim().toLowerCase();
    if (accounts.containsKey(normalized)) {
      return accounts[normalized];
    }
    for (final acc in accounts.values) {
      final name = (acc['fullName'] ?? acc['name'] ?? acc['username'] ?? '').toString().trim().toLowerCase();
      if (name == normalized) {
        return acc;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getOfflineAccountById(int id) async {
    final accounts = await getOfflineAccounts();
    for (final acc in accounts.values) {
      if (acc['id'] == id) return acc;
    }
    return null;
  }

  Future<void> saveOfflineAccount(Map<String, dynamic> account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accounts = await getOfflineAccounts();
      final username = (account['fullName'] ?? account['username'] ?? account['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (username.isNotEmpty) {
        accounts[username] = account;
        await prefs.setString(_offlineAccountsKey, jsonEncode(accounts));
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving offline account: $e');
    }
  }

  // --- Scoped Birthdays Storage ---
  Future<List<BirthdayModel>> loadBirthdays({int? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUserId = userId ?? prefs.getInt(_activeOfflineSessionKey);
      final key = effectiveUserId != null ? 't2w_local_birthdays_$effectiveUserId' : _birthdaysKey;
      var jsonStr = prefs.getString(key);
      if ((jsonStr == null || jsonStr.isEmpty) && effectiveUserId != null) {
        jsonStr = prefs.getString(_birthdaysKey);
      }
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((item) => BirthdayModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading birthdays: $e');
    }
    return [];
  }

  Future<void> saveBirthdays(List<BirthdayModel> birthdays, {int? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUserId = userId ?? prefs.getInt(_activeOfflineSessionKey);
      final key = effectiveUserId != null ? 't2w_local_birthdays_$effectiveUserId' : _birthdaysKey;
      final list = birthdays.map((b) => b.toJson()).toList();
      await prefs.setString(key, jsonEncode(list));
      if (effectiveUserId == null) {
        await prefs.setString(_birthdaysKey, jsonEncode(list));
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving birthdays: $e');
    }
  }

  // --- Gifts Storage ---
  Future<Map<int, List<GiftModel>>> loadGifts() async {
    final Map<int, List<GiftModel>> map = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_giftsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = jsonDecode(jsonStr);
        rawMap.forEach((key, value) {
          final int? birthdayId = int.tryParse(key);
          if (birthdayId == null) return;
          final List list = value;
          int seq = 1;
          map[birthdayId] = list.map((g) {
            final raw = g as Map<String, dynamic>;
            return GiftModel.fromJson(raw, birthdayId * 1000 + (seq++));
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading gifts: $e');
    }
    return map;
  }

  Future<void> saveGifts(Map<int, List<GiftModel>> giftsCache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      giftsCache.forEach((birthdayId, gifts) {
        rawMap[birthdayId.toString()] = gifts.map((g) => g.toJson()).toList();
      });
      await prefs.setString(_giftsKey, jsonEncode(rawMap));
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving gifts: $e');
    }
  }

  // --- Contacts Storage ---
  Future<List<ContactModel>> loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_contactsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((c) => ContactModel.fromJson(c)).toList();
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading contacts: $e');
    }
    return [];
  }

  Future<void> saveContacts(List<ContactModel> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = contacts.map((c) => c.toJson()).toList();
      await prefs.setString(_contactsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving contacts: $e');
    }
  }

  // --- User Profile Storage ---
  Future<Map<String, dynamic>?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_profileKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr);
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading profile: $e');
    }
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile));
    } catch (e) {
      debugPrint('[LocalStorageService] Error saving profile: $e');
    }
  }
}
