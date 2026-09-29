import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/providers/app_state.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/voice_assistant_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mic_button.dart';
import '../../core/utils/speech_manager.dart';


class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key, this.onNavigate});

  final ValueChanged<VoiceIntentResult>? onNavigate;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _speech = SpeechManager.instance;
  final TtsService _tts = TtsService();

  bool _listening = false;
  bool _speechAvailable = false;
  bool _processed = false;
  String _status = 'மைக் அழுத்தி தமிழில் பேசுங்கள் / Speak in Tamil';
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          if (mounted && !_processed && _recognizedText.trim().isNotEmpty) {
            _processCommand(_recognizedText);
          }
        },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            if (!_processed && _recognizedText.trim().isNotEmpty) {
              _processCommand(_recognizedText);
            } else if (mounted) {
              setState(() => _listening = false);
            }
          }
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {}
  }

  String get _userLocale {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    return lang == 'ta'
        ? 'ta-IN'
        : lang == 'te'
            ? 'te-IN'
            : lang == 'hi'
                ? 'hi-IN'
                : 'en-IN';
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Voice input not supported on this device.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_listening) {
      if (_recognizedText.trim().isNotEmpty) {
        _processCommand(_recognizedText);
      } else {
        await _speech.stop();
        setState(() => _listening = false);
      }
      return;
    }

    // Stop speech recognition globally if any instance is listening and wait 100ms for resources to release
    if (_speech.isListening) {
      try {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    }

    setState(() {
      _listening = true;
      _processed = false;
      _recognizedText = '';
      _status = 'கேட்கிறது... இப்போது பேசுங்கள்';
    });

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: _userLocale,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
        ),
        onResult: (result) {
          if (!mounted || _processed) return;
          final words = result.recognizedWords.trim();
          setState(() => _recognizedText = words);

          if (words.isEmpty) return;

          final intent = VoiceAssistantService.parseCommand(words, _userLocale);
          final isExplicitNav = intent.intent == VoiceIntentType.navigateHome ||
              intent.intent == VoiceIntentType.navigateBookings ||
              intent.intent == VoiceIntentType.navigateProfile ||
              intent.intent == VoiceIntentType.navigateSearch;

          if (result.finalResult || isExplicitNav) {
            _processCommand(words);
          }
        },
      );
    } catch (e) {
      debugPrint('Voice screen listen error: $e');
    }
  }

  void _processCommand(String text) {
    if (_processed) return;
    _processed = true;

    _speech.stop();
    if (mounted) setState(() => _listening = false);

    final result = VoiceAssistantService.parseCommand(text, _userLocale);
    if (mounted) setState(() => _status = result.feedbackMessage);

    // Speak audio feedback
    Future.microtask(() async {
      await _tts.setLanguage(_userLocale);
      await _tts.speak(result.feedbackMessage);
    });

    if (widget.onNavigate != null) {
      widget.onNavigate!(result);
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Wave icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (_listening ? AppColors.error : AppColors.primary).withAlpha(20),
              ),
              child: Icon(
                _listening ? Icons.graphic_eq_rounded : Icons.record_voice_over_rounded,
                size: 88,
                color: _listening ? AppColors.error : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              _status,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            if (_recognizedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Text(
                  '“$_recognizedText”',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              'தமிழில் சொல்லுங்கள்:\n• "முன்பதிவு" • "டிராக்டர்" • "முகப்பு" • "சுயவிவரம்"',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            MicButton(onPressed: _toggleListening, isListening: _listening),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
