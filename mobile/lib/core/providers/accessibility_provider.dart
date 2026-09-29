import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central state provider for Uzhavan Accessibility & Inclusivity Features.
class AccessibilityProvider extends ChangeNotifier {
  AccessibilityProvider() {
    _loadPreferences();
  }

  bool _isHighContrast = false;
  bool _isPictogramMode = false;
  bool _dirtyHandsMode = false;
  double _fontSizeScale = 1.0; // 1.0 to 1.5x font scaling
  bool _voiceAutoRead = false;
  bool _hapticFeedbackEnabled = true;
  bool _shakeToVoice = true;

  // Visual Screen Spotlight Reader State
  bool _spotlightActive = false;
  int _activeSpotlightIndex = -1;
  String _spotlightText = '';

  // Getters
  bool get isHighContrast => _isHighContrast;
  bool get isPictogramMode => _isPictogramMode;
  bool get dirtyHandsMode => _dirtyHandsMode;
  double get fontSizeScale => _fontSizeScale;
  bool get voiceAutoRead => _voiceAutoRead;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get shakeToVoice => _shakeToVoice;

  bool get spotlightActive => _spotlightActive;
  int get activeSpotlightIndex => _activeSpotlightIndex;
  String get spotlightText => _spotlightText;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isHighContrast = prefs.getBool('acc_high_contrast') ?? false;
      _isPictogramMode = prefs.getBool('acc_pictogram_mode') ?? false;
      _dirtyHandsMode = prefs.getBool('acc_dirty_hands') ?? false;
      _fontSizeScale = prefs.getDouble('acc_font_scale') ?? 1.0;
      _voiceAutoRead = prefs.getBool('acc_voice_auto_read') ?? false;
      _hapticFeedbackEnabled = prefs.getBool('acc_haptic_enabled') ?? true;
      _shakeToVoice = prefs.getBool('acc_shake_to_voice') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setHighContrast(bool value) async {
    _isHighContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_high_contrast', value);
  }

  Future<void> setPictogramMode(bool value) async {
    _isPictogramMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_pictogram_mode', value);
  }

  Future<void> setDirtyHandsMode(bool value) async {
    _dirtyHandsMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_dirty_hands', value);
  }

  Future<void> setFontSizeScale(double scale) async {
    _fontSizeScale = scale.clamp(1.0, 1.5);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('acc_font_scale', _fontSizeScale);
  }

  Future<void> setVoiceAutoRead(bool value) async {
    _voiceAutoRead = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_voice_auto_read', value);
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedbackEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_haptic_enabled', value);
  }

  Future<void> setShakeToVoice(bool value) async {
    _shakeToVoice = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acc_shake_to_voice', value);
  }

  // Spotlight controls
  void startSpotlight() {
    _spotlightActive = true;
    _activeSpotlightIndex = 0;
    _spotlightText = '';
    notifyListeners();
  }

  void updateSpotlight(int index, String text) {
    _activeSpotlightIndex = index;
    _spotlightText = text;
    notifyListeners();
  }

  void stopSpotlight() {
    _spotlightActive = false;
    _activeSpotlightIndex = -1;
    _spotlightText = '';
    notifyListeners();
  }
}
