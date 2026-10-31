import 'package:flutter/services.dart';
import 'audio_feedback_stub.dart' if (dart.library.js) 'audio_feedback_web.dart';

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
