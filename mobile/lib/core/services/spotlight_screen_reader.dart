import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import 'tts_service.dart';

class SpotlightItem {
  SpotlightItem({
    required this.index,
    required this.label,
    required this.textToSpeak,
  });

  final int index;
  final String label;
  final String textToSpeak;
}

/// Controller for visual screen spotlight reading.
/// Sequentially speaks page content aloud while visually illuminating active cards with a glowing border.
class SpotlightScreenReader {
  static final SpotlightScreenReader _instance = SpotlightScreenReader._internal();
  factory SpotlightScreenReader() => _instance;
  SpotlightScreenReader._internal();

  final TtsService _tts = TtsService();
  List<SpotlightItem> _currentItems = [];
  int _currentIndex = 0;
  bool _isScanning = false;

  bool get isScanning => _isScanning;

  Future<void> startScan(BuildContext context, List<SpotlightItem> items, {String langCode = 'ta-IN'}) async {
    if (items.isEmpty) return;
    _currentItems = items;
    _currentIndex = 0;
    _isScanning = true;

    final accProvider = context.read<AccessibilityProvider>();
    accProvider.startSpotlight();

    await _tts.setLanguage(langCode);
    await _readCurrentItem(context);
  }

  Future<void> _readCurrentItem(BuildContext context) async {
    if (!_isScanning || _currentIndex >= _currentItems.length) {
      stopScan(context);
      return;
    }

    final item = _currentItems[_currentIndex];
    final accProvider = context.read<AccessibilityProvider>();
    accProvider.updateSpotlight(item.index, item.textToSpeak);

    await _tts.speak(item.textToSpeak);

    // Wait for TTS to finish speaking before moving to next item
    int checks = 0;
    while (_tts.isSpeaking && _isScanning && checks < 50) {
      await Future.delayed(const Duration(milliseconds: 200));
      checks++;
    }

    if (_isScanning) {
      await Future.delayed(const Duration(milliseconds: 400));
      _currentIndex++;
      if (context.mounted) {
        await _readCurrentItem(context);
      }
    }
  }

  void stopScan(BuildContext context) {
    _isScanning = false;
    _tts.stop();
    context.read<AccessibilityProvider>().stopSpotlight();
  }
}
