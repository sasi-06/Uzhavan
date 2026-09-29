import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/haptic_feedback_service.dart';
import '../theme/accessibility_theme.dart';
import '../theme/app_colors.dart';
import '../utils/machine_icons.dart';

/// Machine type names in Tamil, Telugu, Hindi, English
const Map<String, Map<String, String>> machineTypeLabels = {
  'tractor': {'ta': 'டிராக்டர்', 'te': 'ట్రాక్టర్', 'hi': 'ट्रैक्टर', 'en': 'Tractor'},
  'harvester': {'ta': 'அறுவடை', 'te': 'హార్వెస్టర్', 'hi': 'हार्वेस्टर', 'en': 'Harvester'},
  'plough': {'ta': 'உழவு', 'te': 'నాగలి', 'hi': 'हल', 'en': 'Plough'},
  'seeder': {'ta': 'விதைப்பான்', 'te': 'విత్తనాలు', 'hi': 'बीजक', 'en': 'Seeder'},
  'sprayer': {'ta': 'தெளிப்பான்', 'te': 'స్ప్రేయర్', 'hi': 'स्प्रेयर', 'en': 'Sprayer'},
};

class MachineTypeTile extends StatelessWidget {
  const MachineTypeTile({
    super.key,
    required this.type,
    required this.lang,
    this.selected = false,
    this.onTap,
    this.size = 100,
  });

  final String type;
  final String lang;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    final isHC = acc.isHighContrast;
    final isPictogram = acc.isPictogramMode;

    final label = machineTypeLabels[type]?[lang] ?? machineTypeLabels[type]?['en'] ?? type;

    final double effectiveSize = (isPictogram || isHC) ? size * 1.15 : size;
    final double iconScale = isPictogram ? 0.52 : 0.42;

    Color iconColor;
    Color textColor;
    Color borderColor;

    if (isHC) {
      iconColor = selected ? Colors.black : AccessibilityTheme.sunlightYellow;
      textColor = selected ? Colors.black : AccessibilityTheme.sunlightWhite;
      borderColor = AccessibilityTheme.sunlightYellow;
    } else {
      iconColor = selected ? Colors.white : AppColors.primary;
      textColor = selected ? Colors.white : AppColors.textPrimary;
      borderColor = selected ? AppColors.primaryLight : const Color(0xFFE2E8F0);
    }

    return GestureDetector(
      onTap: () {
        if (acc.hapticFeedbackEnabled) {
          HapticFeedbackService.selectionClick();
        }
        if (onTap != null) onTap!();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: effectiveSize,
        height: effectiveSize,
        decoration: BoxDecoration(
          color: isHC
              ? (selected ? AccessibilityTheme.sunlightYellow : AccessibilityTheme.sunlightCard)
              : (selected ? null : Colors.white),
          gradient: (!isHC && selected)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF15803D), Color(0xFF16A34A)],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: selected ? 2.5 : (isHC ? 2 : 1),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (isHC ? AccessibilityTheme.sunlightYellow : AppColors.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(machineIcon(type), size: effectiveSize * iconScale, color: iconColor),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: effectiveSize * 0.125 * acc.fontSizeScale,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
