import 'package:flutter/services.dart';

class DeviceService {
  /// Trigger light haptic vibration feedback for button taps and card selections
  static Future<void> triggerLightHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Trigger medium haptic vibration feedback for major actions (saving, adding, reserving)
  static Future<void> triggerMediumHaptic() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Trigger success haptic pattern for completed flows (login, AI wish generated)
  static Future<void> triggerSuccessHaptic() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
