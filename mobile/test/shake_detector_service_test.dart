import 'package:flutter_test/flutter_test.dart';
import 'package:uzhavan/core/services/shake_detector_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShakeDetectorService Algorithm Tests', () {
    test('Stationary phone does not trigger shake', () {
      bool triggered = false;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        onShake: () => triggered = true,
      );

      final result = detector.processAcceleration(0.0, 0.0, 0.0, timestampMs: 1000);
      expect(result, isFalse);
      expect(triggered, isFalse);
    });

    test('Gentle walking movement does not trigger shake', () {
      bool triggered = false;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        onShake: () => triggered = true,
      );

      // Normal walking acceleration is usually 2.0 to 4.0 m/s^2
      final result1 = detector.processAcceleration(2.0, 1.5, 3.0, timestampMs: 1000);
      final result2 = detector.processAcceleration(-2.5, 1.0, 2.0, timestampMs: 1400);

      expect(result1, isFalse);
      expect(result2, isFalse);
      expect(triggered, isFalse);
    });

    test('Single high-energy vigorous shake triggers immediately', () {
      bool triggered = false;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        strongShakeThresholdGravity: 17.5,
        onShake: () => triggered = true,
      );

      // Vigorous shake: x = 18.0 m/s^2
      final result = detector.processAcceleration(18.0, 0.0, 0.0, timestampMs: 1000);
      expect(result, isTrue);
      expect(triggered, isTrue);
    });

    test('Dual-stroke shake triggers on second stroke within window', () {
      int triggerCount = 0;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        shakeThresholdGravity: 12.5,
        shakeSlopTimeMs: 250,
        shakeCountResetTimeMs: 1000,
        onShake: () => triggerCount++,
      );

      // Stroke 1: at t=1000 ms, magnitude = 13.0
      final r1 = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 1000);
      expect(r1, isFalse);
      expect(triggerCount, 0);

      // Stroke too fast (slop time = 250ms), at t=1100 ms
      final rTooSoon = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 1100);
      expect(rTooSoon, isFalse);
      expect(triggerCount, 0);

      // Stroke 2: at t=1400 ms (400ms after first stroke, within 1000ms window)
      final r2 = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 1400);
      expect(r2, isTrue);
      expect(triggerCount, 1);
    });

    test('Window expiration resets shake stroke count', () {
      int triggerCount = 0;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        shakeThresholdGravity: 12.5,
        shakeSlopTimeMs: 250,
        shakeCountResetTimeMs: 1000,
        onShake: () => triggerCount++,
      );

      // Stroke 1: at t=1000 ms
      detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 1000);
      expect(triggerCount, 0);

      // Stroke 2 arrives 1500ms later (t=2500 ms) > reset window (1000ms)
      final rExpired = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 2500);
      expect(rExpired, isFalse);
      expect(triggerCount, 0);

      // Follow-up stroke at t=2800 ms within the new window triggers!
      final rValid = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 2800);
      expect(rValid, isTrue);
      expect(triggerCount, 1);
    });

    test('Cooldown suppresses subsequent triggers for cooldownDurationMs', () {
      int triggerCount = 0;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        cooldownDurationMs: 2000,
        strongShakeThresholdGravity: 17.5,
        onShake: () => triggerCount++,
      );

      // First trigger
      final r1 = detector.processAcceleration(20.0, 0.0, 0.0, timestampMs: 1000);
      expect(r1, isTrue);
      expect(triggerCount, 1);

      // Stroke during cooldown at t=1800 ms (800ms later, cooldown is 2000ms)
      final rSuppressed = detector.processAcceleration(20.0, 0.0, 0.0, timestampMs: 1800);
      expect(rSuppressed, isFalse);
      expect(triggerCount, 1);

      // Stroke after cooldown at t=3100 ms (2100ms later)
      final rAfterCooldown = detector.processAcceleration(20.0, 0.0, 0.0, timestampMs: 3100);
      expect(rAfterCooldown, isTrue);
      expect(triggerCount, 2);
    });

    test('Single-shake mode triggers on single standard stroke', () {
      int triggerCount = 0;
      final detector = ShakeDetectorService(
        enableHaptics: false,
        minShakeCount: 1,
        shakeThresholdGravity: 12.0,
        onShake: () => triggerCount++,
      );

      final result = detector.processAcceleration(13.0, 0.0, 0.0, timestampMs: 1000);
      expect(result, isTrue);
      expect(triggerCount, 1);
    });
  });
}
