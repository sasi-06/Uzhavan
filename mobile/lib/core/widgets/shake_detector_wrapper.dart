import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/shake_detector_service.dart';
import 'global_voice_overlay.dart';

/// Wraps any screen or shell with accelerometer shake detection.
/// Automatically starts/stops listening based on [AccessibilityProvider.shakeToVoice].
/// When a valid physical shake is detected, invokes [onShake] and triggers haptic feedback.
class ShakeDetectorWrapper extends StatefulWidget {
  const ShakeDetectorWrapper({
    super.key,
    required this.child,
    required this.onShake,
  });

  final Widget child;
  final VoidCallback onShake;

  @override
  State<ShakeDetectorWrapper> createState() => _ShakeDetectorWrapperState();
}

class _ShakeDetectorWrapperState extends State<ShakeDetectorWrapper> {
  late final ShakeDetectorService _detector;

  @override
  void initState() {
    super.initState();
    _detector = ShakeDetectorService(
      onShake: _handleShakeTrigger,
    );
  }

  void _handleShakeTrigger() {
    if (!mounted) return;
    // Prevent re-opening or stacking voice sheet if it is already open
    if (GlobalVoiceOverlay.isShowing) return;
    widget.onShake();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final acc = context.watch<AccessibilityProvider>();
    if (acc.shakeToVoice) {
      if (!_detector.isListening) {
        _detector.startListening();
      }
    } else {
      if (_detector.isListening) {
        _detector.stopListening();
      }
    }
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
