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

  // Reminder settings keys
  static const _keyRemindersEnabled = 't2w_reminders_enabled';
  static const _keyReminderHour = 't2w_reminder_hour';
  static const _keyReminderMinute = 't2w_reminder_minute';
  static const _keyNotifyJ7 = 't2w_notify_j7';
  static const _keyNotifyJ3 = 't2w_notify_j3';
  static const _keyNotifyJ1 = 't2w_notify_j1';
  static const _keyNotifyDay0 = 't2w_notify_day0';
  static const _keySoundEnabled = 't2w_sound_enabled';
  static const _keyVibrationEnabled = 't2w_vibration_enabled';

  /// Get current reminder settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyRemindersEnabled) ?? true,
      'hour': prefs.getInt(_keyReminderHour) ?? 9,
      'minute': prefs.getInt(_keyReminderMinute) ?? 0,
      'j7': prefs.getBool(_keyNotifyJ7) ?? true,
      'j3': prefs.getBool(_keyNotifyJ3) ?? true,
      'j1': prefs.getBool(_keyNotifyJ1) ?? true,
      'day0': prefs.getBool(_keyNotifyDay0) ?? true,
      'sound': prefs.getBool(_keySoundEnabled) ?? true,
      'vibration': prefs.getBool(_keyVibrationEnabled) ?? true,
    };
  }

  /// Save reminder settings and optionally reschedule all reminders
  static Future<void> saveSettings({
    required bool enabled,
    required int hour,
    required int minute,
    required bool j7,
    required bool j3,
    required bool j1,
    required bool day0,
    required bool sound,
    required bool vibration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemindersEnabled, enabled);
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);
    await prefs.setBool(_keyNotifyJ7, j7);
    await prefs.setBool(_keyNotifyJ3, j3);
    await prefs.setBool(_keyNotifyJ1, j1);
    await prefs.setBool(_keyNotifyDay0, day0);
    await prefs.setBool(_keySoundEnabled, sound);
    await prefs.setBool(_keyVibrationEnabled, vibration);
    debugPrint('[NotificationService] Reminder settings updated: $hour:$minute (J7:$j7, J3:$j3, J1:$j1, J0:$day0)');
  }

  /// Calculate the next occurrence date for a birthday at configured time
  static DateTime _getNextBirthdayDate(DateTime birthdate, [int hour = 9, int minute = 0]) {
    final now = DateTime.now();
    var next = DateTime(now.year, birthdate.month, birthdate.day, hour, minute);
    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, birthdate.month, birthdate.day, hour, minute);
    }
    return next;
  }

  /// Schedules birthday reminders according to user settings
  static Future<List<ScheduledReminder>> scheduleBirthdayReminder(BirthdayModel birthday) async {
    final settings = await getSettings();
    final bool enabled = settings['enabled'] as bool;
    if (!enabled) {
      await cancelBirthdayReminder(birthday.id);
      return [];
    }

    final int hour = settings['hour'] as int;
    final int minute = settings['minute'] as int;
    final bool notifyJ7 = settings['j7'] as bool;
    final bool notifyJ3 = settings['j3'] as bool;
    final bool notifyJ1 = settings['j1'] as bool;
    final bool notifyDay0 = settings['day0'] as bool;

    final nextBd = _getNextBirthdayDate(birthday.birthdate, hour, minute);
    final now = DateTime.now();

    final reminders = <ScheduledReminder>[];

    // J-7 reminder
    if (notifyJ7) {
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
    }

    // J-3 reminder
    if (notifyJ3) {
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
    }

    // J-1 reminder
    if (notifyJ1) {
      final j1Date = nextBd.subtract(const Duration(days: 1));
      if (j1Date.isAfter(now)) {
        reminders.add(ScheduledReminder(
          id: '${birthday.id}_j1',
          birthdayId: birthday.id,
          birthdayName: birthday.name,
          type: 'J-1',
          scheduledDate: j1Date,
          title: 'Demain : Anniversaire de ${birthday.name} ⏰',
          message: 'C\'est demain ! Êtes-vous prêt pour lui souhaiter un joyeux anniversaire ?',
        ));
      }
    }

    // Day of (Jour J)
    if (notifyDay0) {
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
    }

    await _saveRemindersForBirthday(birthday.id, reminders);
    debugPrint('[NotificationService] Scheduled ${reminders.length} reminder(s) for ${birthday.name}');
    return reminders;
  }

  /// Reschedule all reminders for a list of birthdays
  static Future<void> rescheduleAll(List<BirthdayModel> birthdays) async {
    for (final b in birthdays) {
      await scheduleBirthdayReminder(b);
    }
    debugPrint('[NotificationService] Rescheduled all reminders for ${birthdays.length} birthday(s)');
  }

  /// Trigger an immediate test push / reminder notification
  static Future<ScheduledReminder> sendTestNotification({
    String? title,
    String? message,
    String? targetName,
  }) async {
    final now = DateTime.now();
    final name = targetName ?? 'Sophie Martin';
    final reminder = ScheduledReminder(
      id: 'test_${now.millisecondsSinceEpoch}',
      birthdayId: 0,
      birthdayName: name,
      type: 'TEST_PUSH',
      scheduledDate: now,
      title: title ?? '🔔 Notification Push Test · Time2Wish',
      message: message ?? 'C\'est l\'anniversaire de $name aujourd\'hui ! Les rappels push fonctionnent parfaitement.',
      isTriggered: true,
    );

    // Save into history
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllReminders();
      all.insert(0, reminder);
      final jsonStr = jsonEncode(all.map((r) => r.toJson()).toList());
      await prefs.setString(_remindersKey, jsonStr);
    } catch (e) {
      debugPrint('[NotificationService] Error saving test notification: $e');
    }

    return reminder;
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
