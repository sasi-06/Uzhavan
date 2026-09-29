import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class PriceChip extends StatelessWidget {
  const PriceChip({
    super.key,
    required this.displayPrice,
    this.spokenPrice,
    this.fontSize = 22,
    this.lang = 'ta-IN',
  });

  final String displayPrice;
  final String? spokenPrice;
  final double fontSize;
  final String lang;

  void _speak() {
    final tts = TtsService();
    tts.setLanguage(lang);
    tts.speak(spokenPrice ?? displayPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          displayPrice,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _speak,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
          ),
        ),
      ],
    );
  }
}
