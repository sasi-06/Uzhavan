import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Centralized Text-To-Speech (TTS) engine for Uzhavan.
/// Speaks back to farmers in their preferred local language (Tamil, Telugu, Hindi, English).
class TtsService {
  factory TtsService() => _instance;
  TtsService._internal() {
    _init();
  }

  static final TtsService _instance = TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'ta-IN';

  bool get isSpeaking => _isSpeaking;

  Future<void> _init() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(0.45); // Slightly slower rate for clear understanding by farmers
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        final str = msg.toString();
        if (str.contains('not-allowed') ||
            str.contains('SpeechSynthesis') ||
            str.contains('interrupted') ||
            str.contains('canceled')) {
          return;
        }
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }

  /// Sets the TTS spoken language code (e.g. 'ta-IN', 'te-IN', 'hi-IN', 'en-IN').
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    if (_isInitialized) {
      try {
        await _flutterTts.setLanguage(languageCode);
      } catch (e) {
        debugPrint('Error setting TTS language $languageCode: $e');
      }
    }
  }

  /// Speaks the given text string out loud to the user.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      if (_isSpeaking) {
        await stop();
      }
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stops current speech output.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}

/// Convenience class for static TTSService access
class TTSService {
  static final TtsService _tts = TtsService();

  static Future<void> speak(String text, {String lang = 'ta'}) async {
    final code = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN', 'en': 'en-IN'}[lang] ?? 'ta-IN';
    await _tts.setLanguage(code);
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}
