import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/spotlight_screen_reader.dart';
import '../services/tts_service.dart';
import '../theme/accessibility_theme.dart';
import '../theme/app_colors.dart';

/// Prominent Tamil/Local language Audio Reader button for farmers.
/// Speaks out screen content aloud or initiates visual Spotlight Screen Scanning.
class PageVoiceReaderButton extends StatefulWidget {
  const PageVoiceReaderButton({
    super.key,
    required this.textToRead,
    this.label = '🔊 கேளுங்கள்',
    this.languageCode = 'ta-IN',
    this.compact = false,
    this.spotlightItems,
  });

  final String textToRead;
  final String label;
  final String languageCode;
  final bool compact;
  final List<SpotlightItem>? spotlightItems;

  @override
  State<PageVoiceReaderButton> createState() => _PageVoiceReaderButtonState();
}

class _PageVoiceReaderButtonState extends State<PageVoiceReaderButton> {
  final TtsService _tts = TtsService();
  final SpotlightScreenReader _spotlightReader = SpotlightScreenReader();
  bool _speaking = false;

  Future<void> _toggleSpeak() async {
    final acc = context.read<AccessibilityProvider>();

    if (widget.spotlightItems != null && widget.spotlightItems!.isNotEmpty) {
      if (acc.spotlightActive) {
        _spotlightReader.stopScan(context);
        setState(() => _speaking = false);
      } else {
        setState(() => _speaking = true);
        await _spotlightReader.startScan(
          context,
          widget.spotlightItems!,
          langCode: widget.languageCode,
        );
        if (mounted) setState(() => _speaking = false);
      }
      return;
    }

    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      await _tts.setLanguage(widget.languageCode);
      await _tts.speak(widget.textToRead);
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.watch<AccessibilityProvider>().isHighContrast;
    final primaryColor = AccessibilityTheme.getPrimaryColor(context);

    if (widget.compact) {
      return IconButton(
        onPressed: _toggleSpeak,
        tooltip: 'கேளுங்கள்',
        icon: Icon(
          _speaking ? Icons.volume_up_rounded : Icons.campaign_rounded,
          color: _speaking ? primaryColor : (isHC ? AccessibilityTheme.sunlightYellow : AppColors.textSecondary),
        ),
      );
    }

    return InkWell(
      onTap: _toggleSpeak,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _speaking ? primaryColor : primaryColor.withAlpha(isHC ? 60 : 25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _speaking ? Icons.volume_up_rounded : Icons.campaign_rounded,
              color: _speaking ? (isHC ? Colors.black : Colors.white) : primaryColor,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              _speaking ? 'பேசுகிறது...' : widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _speaking ? (isHC ? Colors.black : Colors.white) : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
