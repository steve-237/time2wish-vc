import 'package:flutter/services.dart';
import 'audio_feedback_stub.dart' if (dart.library.js_interop) 'audio_feedback_web.dart';

class DeviceService {
  /// Play an immediate soft click sound (Web Audio + SystemSound)
  static void playTapSound() {
    try {
      SystemSound.play(SystemSoundType.click);
      playWebAudio('click');
    } catch (_) {}
  }

  /// Play a melodic success chord (chime)
  static void playSuccessSound() {
    try {
      SystemSound.play(SystemSoundType.click);
      playWebAudio('success');
    } catch (_) {}
  }

  /// Play an uplifting celebration fanfare sound
  static void playCelebrationSound() {
    try {
      SystemSound.play(SystemSoundType.click);
      playWebAudio('celebrate');
    } catch (_) {}
  }

  /// Play a gentle error / warning alert tone
  static void playErrorSound() {
    try {
      SystemSound.play(SystemSoundType.alert);
      playWebAudio('error');
    } catch (_) {}
  }

  /// Trigger error haptic vibration + sound feedback
  static Future<void> triggerErrorHaptic() async {
    try {
      playErrorSound();
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Trigger light haptic vibration + tap sound for buttons and card selections
  static Future<void> triggerLightHaptic() async {
    try {
      playTapSound();
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Trigger medium haptic vibration + sound feedback for major actions (saving, adding, reserving)
  static Future<void> triggerMediumHaptic() async {
    try {
      playSuccessSound();
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Trigger success haptic pattern + celebration sound for completed flows
  static Future<void> triggerSuccessHaptic() async {
    try {
      playCelebrationSound();
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
