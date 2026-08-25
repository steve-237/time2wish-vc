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

  // --- Birthdays Storage ---
  Future<List<BirthdayModel>> loadBirthdays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_birthdaysKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((item) => BirthdayModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Error loading birthdays: $e');
    }
    return [];
  }

  Future<void> saveBirthdays(List<BirthdayModel> birthdays) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = birthdays.map((b) => b.toJson()).toList();
      await prefs.setString(_birthdaysKey, jsonEncode(list));
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
          final int birthdayId = int.parse(key);
          final List list = value;
          map[birthdayId] = list.map((g) => GiftModel.fromJson(g)).toList();
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
