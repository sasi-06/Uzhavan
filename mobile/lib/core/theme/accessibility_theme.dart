import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import 'app_colors.dart';

/// High-Contrast & Outdoor Sunlight Theme System for Uzhavan.
class AccessibilityTheme {
  // High-Contrast Outdoor Palette (Vivid Yellow/Green on Deep Black)
  static const Color sunlightBlack = Color(0xFF0A0E14);
  static const Color sunlightCard = Color(0xFF1E2630);
  static const Color sunlightYellow = Color(0xFFFFD700);
  static const Color sunlightGreen = Color(0xFF00E676);
  static const Color sunlightRed = Color(0xFFFF1744);
  static const Color sunlightWhite = Color(0xFFFFFFFF);

  static bool _isHC(BuildContext context) {
    try {
      return Provider.of<AccessibilityProvider>(context, listen: false).isHighContrast;
    } catch (_) {
      return false;
    }
  }

  static double _fontScale(BuildContext context) {
    try {
      return Provider.of<AccessibilityProvider>(context, listen: false).fontSizeScale;
    } catch (_) {
      return 1.0;
    }
  }

  /// Resolves background color based on high-contrast mode state
  static Color getBackgroundColor(BuildContext context) {
    return _isHC(context) ? sunlightBlack : AppColors.background;
  }

  /// Resolves card container color
  static Color getCardColor(BuildContext context) {
    return _isHC(context) ? sunlightCard : Colors.white;
  }

  /// Resolves primary action color
  static Color getPrimaryColor(BuildContext context) {
    return _isHC(context) ? sunlightYellow : AppColors.primary;
  }

  /// Resolves primary text color
  static Color getTextPrimaryColor(BuildContext context) {
    return _isHC(context) ? sunlightWhite : AppColors.textPrimary;
  }

  /// Resolves secondary text color
  static Color getTextSecondaryColor(BuildContext context) {
    return _isHC(context) ? sunlightYellow : AppColors.textSecondary;
  }

  /// Minimum touch target size (senior / dirty hands mode enlarged touch target: 64dp)
  static double getMinTouchTarget(BuildContext context) {
    return _isHC(context) ? 64.0 : 48.0;
  }

  /// Scaled text style multiplier
  static TextStyle getScaledTextStyle(BuildContext context, TextStyle style) {
    final scale = _fontScale(context);
    final isHC = _isHC(context);

    Color color = style.color ?? AppColors.textPrimary;
    if (isHC) {
      if (color == AppColors.textPrimary || color == Colors.black || color == Colors.black87) {
        color = sunlightWhite;
      } else if (color == AppColors.textSecondary || color == Colors.grey.shade600) {
        color = sunlightYellow;
      } else if (color == AppColors.primary) {
        color = sunlightYellow;
      }
    }

    return style.copyWith(
      fontSize: (style.fontSize ?? 14.0) * scale,
      color: color,
      fontWeight: isHC ? FontWeight.bold : style.fontWeight,
    );
  }
}
