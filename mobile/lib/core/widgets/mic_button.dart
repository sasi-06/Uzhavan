import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modern persistent microphone floating action button.
/// Features a rich emerald gradient, ambient glow shadow, and interactive pulse response.
class MicButton extends StatelessWidget {
  const MicButton({super.key, this.onPressed, this.isListening = false});

  final VoidCallback? onPressed;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final activeColor = isListening ? AppColors.error : AppColors.primary;
    final gradientColors = isListening
        ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
        : [const Color(0xFF22C55E), const Color(0xFF15803D)];

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: isListening ? 0.5 : 0.35),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        shape: const CircleBorder(),
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
