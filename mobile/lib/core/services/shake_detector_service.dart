import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'haptic_feedback_service.dart';

/// Shake Detector Service for Hands-Free & Accessibility Voice Activation.
/// Detects physical phone shake gestures using the accelerometer (UserAccelerometerEvent,
/// which excludes gravity for clean linear motion detection).
///
/// Implements dual-threshold shake detection:
/// 1. Dual-stroke confirmation (shake-shake): requires 2 acceleration peaks > [shakeThresholdGravity]
///    spaced at least [shakeSlopTimeMs] apart within a [shakeCountResetTimeMs] window.
///    This reliably prevents false positives during normal pocket walking or bumpy tractor rides.
/// 2. Single vigorous shake: a single high-energy acceleration spike > [strongShakeThresholdGravity]
///    triggers immediate activation.
/// 3. Debounce cooldown: Once triggered, suppresses further events for [cooldownDurationMs]
///    to avoid re-triggering while the phone is being stabilized.
class ShakeDetectorService {
  ShakeDetectorService({
    this.onShake,
    this.shakeThresholdGravity = 12.5, // m/s^2 linear acceleration
    this.strongShakeThresholdGravity = 17.5, // m/s^2 high-energy instant shake
    this.shakeSlopTimeMs = 250, // min interval between strokes
    this.shakeCountResetTimeMs = 1000, // time window for accumulating shakes
    this.cooldownDurationMs = 2000, // cooldown after trigger
    this.minShakeCount = 2,
    this.enableHaptics = true,
  });

  final VoidCallback? onShake;
  final double shakeThresholdGravity;
  final double strongShakeThresholdGravity;
  final int shakeSlopTimeMs;
  final int shakeCountResetTimeMs;
  final int cooldownDurationMs;
  final int minShakeCount;
  final bool enableHaptics;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  bool _isListening = false;
  bool get isListening => _isListening;

  int _shakeCount = 0;
  int _firstShakeTime = 0;
  int _lastShakeTime = 0;
  int _lastTriggerTime = 0;

  /// Starts listening to the device's accelerometer.
  void startListening({VoidCallback? onShakeCallback}) {
    if (_isListening) return;
    try {
      _subscription = userAccelerometerEventStream().listen(
        (UserAccelerometerEvent event) {
          processAcceleration(event.x, event.y, event.z);
        },
        onError: (err) {
          debugPrint('ShakeDetector error: $err');
        },
        cancelOnError: false,
      );
      _isListening = true;
    } catch (e) {
      debugPrint('ShakeDetector not supported on this platform/device: $e');
    }
  }

  /// Stops listening and resets shake counters.
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _shakeCount = 0;
  }

  /// Disposes resources.
  void dispose() {
    stopListening();
  }

  /// Evaluates an acceleration sample (x, y, z) in m/s^2.
  /// Returns `true` if a valid shake gesture is recognized and triggered.
  /// Exposed publicly to enable deterministic unit testing without physical sensors.
  bool processAcceleration(double x, double y, double z, {int? timestampMs}) {
    final now = timestampMs ?? DateTime.now().millisecondsSinceEpoch;

    // Cooldown check (only applies if a trigger has already occurred)
    if (_lastTriggerTime > 0 && (now - _lastTriggerTime < cooldownDurationMs)) {
      return false;
    }

    // Magnitude of linear acceleration (gravity already subtracted)
    final double magnitude = sqrt(x * x + y * y + z * z);

    // Instant strong shake check (single energetic stroke)
    if (magnitude >= strongShakeThresholdGravity) {
      _shakeCount = 0;
      _lastTriggerTime = now;
      if (enableHaptics) {
        HapticFeedbackService.micPulse();
      }
      onShake?.call();
      return true;
    }

    // Standard shake stroke check
    if (magnitude >= shakeThresholdGravity) {
      if (_shakeCount == 0) {
        _firstShakeTime = now;
        _lastShakeTime = now;
        _shakeCount = 1;
        if (minShakeCount <= 1) {
          _shakeCount = 0;
          _lastTriggerTime = now;
          if (enableHaptics) {
            HapticFeedbackService.micPulse();
          }
          onShake?.call();
          return true;
        }
        return false;
      }

      // Check if too soon (part of the same physical stroke)
      if (now - _lastShakeTime < shakeSlopTimeMs) {
        return false;
      }

      // Check if within window
      if (now - _firstShakeTime <= shakeCountResetTimeMs) {
        _shakeCount++;
        _lastShakeTime = now;

        if (_shakeCount >= minShakeCount) {
          _shakeCount = 0;
          _lastTriggerTime = now;
          if (enableHaptics) {
            HapticFeedbackService.micPulse();
          }
          onShake?.call();
          return true;
        }
      } else {
        // Window expired; restart sequence with this stroke
        _firstShakeTime = now;
        _lastShakeTime = now;
        _shakeCount = 1;
      }
    }

    return false;
  }
}
