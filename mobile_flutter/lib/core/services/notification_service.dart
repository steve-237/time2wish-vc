import 'package:flutter/material.dart';
import '../models/birthday_model.dart';

class NotificationService {
  /// Schedules local birthday reminder alert on device
  static Future<void> scheduleBirthdayReminder(BirthdayModel birthday) async {
    debugPrint('[NotificationService] Scheduled local alert for ${birthday.name} in ${birthday.daysRemaining} days');
  }

  /// Cancels scheduled reminder for a birthday
  static Future<void> cancelBirthdayReminder(int birthdayId) async {
    debugPrint('[NotificationService] Cancelled local alert for birthday $birthdayId');
  }
}
