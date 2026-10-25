import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birthday_model.dart';
import 'api_service.dart';

enum ReminderType {
  weekBefore,      // J-7
  threeDaysBefore, // J-3
  dayOf,           // Jour J
}

class ScheduledReminder {
  final String id;
  final int birthdayId;
  final String birthdayName;
  final String type; // 'J-7', 'J-3', 'JOUR_J'
  final DateTime scheduledDate;
  final String title;
  final String message;
  final bool isTriggered;

  ScheduledReminder({
    required this.id,
    required this.birthdayId,
    required this.birthdayName,
    required this.type,
    required this.scheduledDate,
    required this.title,
    required this.message,
    this.isTriggered = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'birthdayId': birthdayId,
    'birthdayName': birthdayName,
    'type': type,
    'scheduledDate': scheduledDate.toIso8601String(),
    'title': title,
    'message': message,
    'isTriggered': isTriggered,
  };

  factory ScheduledReminder.fromJson(Map<String, dynamic> json) => ScheduledReminder(
    id: json['id'] as String,
    birthdayId: json['birthdayId'] as int,
    birthdayName: json['birthdayName'] as String,
    type: json['type'] as String,
    scheduledDate: DateTime.parse(json['scheduledDate'] as String),
    title: json['title'] as String,
    message: json['message'] as String,
    isTriggered: (json['isTriggered'] as bool?) ?? false,
  );
}

class NotificationService {
  static const _remindersKey = 't2w_scheduled_reminders';
  static const _fcmTokenKey = 't2w_fcm_token';

  /// Calculate the next occurrence date for a birthday
  static DateTime _getNextBirthdayDate(DateTime birthdate) {
    final now = DateTime.now();
    var next = DateTime(now.year, birthdate.month, birthdate.day, 9, 0);
    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, birthdate.month, birthdate.day, 9, 0);
    }
    return next;
  }

  /// Schedules birthday reminders for J-7, J-3, and day-of (09:00 AM)
  static Future<List<ScheduledReminder>> scheduleBirthdayReminder(BirthdayModel birthday) async {
    final nextBd = _getNextBirthdayDate(birthday.birthdate);
    final now = DateTime.now();

    final reminders = <ScheduledReminder>[];

    // J-7 reminder
    final j7Date = nextBd.subtract(const Duration(days: 7));
    if (j7Date.isAfter(now)) {
      reminders.add(ScheduledReminder(
        id: '${birthday.id}_j7',
        birthdayId: birthday.id,
        birthdayName: birthday.name,
        type: 'J-7',
        scheduledDate: j7Date,
        title: 'J-7 : Anniversaire de ${birthday.name} 🎂',
        message: 'Plus qu\'une semaine ! Pensez à préparer un cadeau ou planifier une surprise.',
      ));
    }

    // J-3 reminder
    final j3Date = nextBd.subtract(const Duration(days: 3));
    if (j3Date.isAfter(now)) {
      reminders.add(ScheduledReminder(
        id: '${birthday.id}_j3',
        birthdayId: birthday.id,
        birthdayName: birthday.name,
        type: 'J-3',
        scheduledDate: j3Date,
        title: 'J-3 : Anniversaire de ${birthday.name} ⏳',
        message: 'Dans 3 jours ! Inspirez-vous avec le générateur de vœux IA de Time2Wish ✨',
      ));
    }

    // Day of (Jour J) at 09:00 AM
    if (nextBd.isAfter(now)) {
      reminders.add(ScheduledReminder(
        id: '${birthday.id}_day0',
        birthdayId: birthday.id,
        birthdayName: birthday.name,
        type: 'JOUR_J',
        scheduledDate: nextBd,
        title: 'C\'est l\'anniversaire de ${birthday.name} aujourd\'hui ! 🎉',
        message: 'Envoyez-lui vos souhaits chaleureux dès maintenant pour illuminer sa journée !',
      ));
    }

    await _saveRemindersForBirthday(birthday.id, reminders);
    debugPrint('[NotificationService] Scheduled ${reminders.length} reminder(s) for ${birthday.name} (J-7, J-3, Jour J)');
    return reminders;
  }

  /// Cancels all scheduled reminders for a given birthday ID
  static Future<void> cancelBirthdayReminder(int birthdayId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allReminders = await getAllReminders();
      allReminders.removeWhere((r) => r.birthdayId == birthdayId);

      final jsonStr = jsonEncode(allReminders.map((r) => r.toJson()).toList());
      await prefs.setString(_remindersKey, jsonStr);
      debugPrint('[NotificationService] Cancelled all reminders for birthday ID $birthdayId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling reminders: $e');
    }
  }

  /// Retrieve all currently scheduled reminders
  static Future<List<ScheduledReminder>> getAllReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_remindersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr);
        return list.map((item) => ScheduledReminder.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[NotificationService] Error loading reminders: $e');
    }
    return [];
  }

  /// Check which reminders are due today
  static Future<List<ScheduledReminder>> getDueReminders() async {
    final all = await getAllReminders();
    final now = DateTime.now();
    return all.where((r) => !r.isTriggered && r.scheduledDate.isBefore(now)).toList();
  }

  /// Internal helper to persist reminders for a specific birthday
  static Future<void> _saveRemindersForBirthday(int birthdayId, List<ScheduledReminder> newReminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllReminders();
      all.removeWhere((r) => r.birthdayId == birthdayId);
      all.addAll(newReminders);

      final jsonStr = jsonEncode(all.map((r) => r.toJson()).toList());
      await prefs.setString(_remindersKey, jsonStr);
    } catch (e) {
      debugPrint('[NotificationService] Error saving reminders: $e');
    }
  }

  /// Register FCM device token with Spring Boot backend
  static Future<void> registerFCMToken(ApiService apiService, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      await apiService.dio.post('/notifications/token', data: {
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('[NotificationService] FCM token registered on backend: $token');
    } catch (e) {
      debugPrint('[NotificationService] FCM token saved locally, offline sync will retry: $e');
    }
  }
}
