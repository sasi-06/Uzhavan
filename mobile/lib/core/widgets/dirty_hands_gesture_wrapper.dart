import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/haptic_feedback_service.dart';
import '../theme/accessibility_theme.dart';

/// Full-screen gesture detector wrapper for Dirty-Hands / Muddy-Field accessibility mode.
/// Allows farmers with wet, dirty, or gloved hands to trigger voice assistant by double tapping anywhere on the screen.
class DirtyHandsGestureWrapper extends StatelessWidget {
  const DirtyHandsGestureWrapper({
    super.key,
    required this.child,
    required this.onGestureTriggered,
  });

  final Widget child;
  final VoidCallback onGestureTriggered;

  void _triggerAction(BuildContext context) {
    HapticFeedbackService.micPulse();
    onGestureTriggered();
  }

  @override
  Widget build(BuildContext context) {
    final accProvider = context.watch<AccessibilityProvider>();
    final isDirtyHands = accProvider.dirtyHandsMode;

    if (!isDirtyHands) return child;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: () => _triggerAction(context),
          onLongPress: () => _triggerAction(context),
          child: child,
        ),

        // Dirty hands active status badge
        Positioned(
          top: 8,
          right: 12,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AccessibilityTheme.getPrimaryColor(context).withAlpha(220),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text(
                    'இருமுறை தொடவும் (Voice)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
