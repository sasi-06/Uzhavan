import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tactile Vibration & Haptic Service for Uzhavan Accessibility.
/// Provides physical tactile confirmation for farmers operating in low-vision or dirty-hands conditions.
class HapticFeedbackService {
  /// Light click feedback for tapping buttons or switching tabs
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Success tactile buzz for booking completion or voice command recognition
  static Future<void> successBuzz() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Alert pulse for errors, network drops, or invalid voice commands
  static Future<void> alertPulse() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }

  /// Mic activation pulse
  static Future<void> micPulse() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic error: $e');
    }
  }
}
