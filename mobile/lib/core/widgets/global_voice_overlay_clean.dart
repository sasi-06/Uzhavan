import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/app_state.dart';
import '../services/tts_service.dart';
import '../services/voice_assistant_service.dart';
import '../theme/app_colors.dart';
import '../utils/speech_manager.dart';

/// Interactive Hands-Free Voice Assistant Sheet.
/// Allows farmers and machine owners to speak commands in Tamil, Tanglish, Telugu, Hindi, or English
/// and automatically navigates / acts across the entire app.
class GlobalVoiceOverlay extends StatefulWidget {
  const GlobalVoiceOverlay({
    super.key,
    required this.languageCode,
    required this.onIntentRecognized,
  });

  final String languageCode;
  final ValueChanged<VoiceIntentResult> onIntentRecognized;

  static void show(
    BuildContext context, {
    required String languageCode,
    required ValueChanged<VoiceIntentResult> onIntentRecognized,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlobalVoiceOverlay(
        languageCode: languageCode,
        onIntentRecognized: onIntentRecognized,
      ),
    );
  }

  @override
  State<GlobalVoiceOverlay> createState() => _GlobalVoiceOverlayState();
}

class _GlobalVoiceOverlayState extends State<GlobalVoiceOverlay>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = SpeechManager.instance;
  final TtsService _tts = TtsService();

  bool _isListening = false;
  bool _processed = false;
  String _liveText = '';
  String _statusText = 'à®®à¯ˆà®•à¯ à®…à®´à¯à®¤à¯à®¤à®¿ à®ªà¯‡à®šà¯à®™à¯à®•à®³à¯ / Speak your request';

  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _initSpeechAndStart();
  }

  Future<void> _initSpeechAndStart() async {
    final appState = context.read<AppState>();
    // Check consecutive voice failures rule: if 2 consecutive failures occurred, silently fallback to tap flow
    if (appState.consecutiveVoiceFailures >= 2) {
      if (mounted) {
        setState(() {
          _statusText = 'à®¤à¯Šà®Ÿà¯à®Ÿà¯à®ªà¯ à®ªà®¯à®©à¯à®ªà®Ÿà¯à®¤à¯à®¤à®µà¯à®®à¯ / Tap to navigate (Tap flow fallback)';
        });
      }
      appState.resetVoiceFailures();
    }

    try {
      final available = await _speech.initialize(
        onError: (e) {
          appState.recordVoiceFailure();
          if (mounted && !_processed && _liveText.trim().isNotEmpty) {
            _handleSpeechResult(_liveText);
          }
        },
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            if (!_processed && _liveText.trim().isNotEmpty) {
              _handleSpeechResult(_liveText);
            } else if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );
      if (mounted) {
        if (available) {
          _startListening();
        } else {
          setState(() {
            _statusText = 'à®•à¯à®°à®²à¯ à®‰à®³à¯à®³à¯€à®Ÿà¯ à®šà¯†à®¯à¯à®¯ à®®à¯à®Ÿà®¿à®¯à®¾à®¤à¯. à®¤à¯Šà®Ÿà¯à®Ÿà¯à®ªà¯ à®ªà®¯à®©à¯à®ªà®Ÿà¯à®¤à¯à®¤à®µà¯à®®à¯';
          });
        }
      }
    } catch (_) {
      appState.recordVoiceFailure();
    }
  }

  Future<void> _startListening() async {
    if (_speech.isListening) {
      try {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    }

    setState(() {
      _isListening = true;
      _processed = false;
      _liveText = '';
      _statusText = 'à®•à¯‡à®Ÿà¯à®•à®¿à®±à®¤à¯... à®‡à®ªà¯à®ªà¯‹à®¤à¯ à®ªà¯‡à®šà¯à®™à¯à®•à®³à¯ / Listening...';
    });

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: widget.languageCode,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!mounted || _processed) return;
          final words = result.recognizedWords.trim();
          setState(() => _liveText = words);

          if (words.isEmpty) return;

          final appState = context.read<AppState>();
          final intent = VoiceAssistantService.parseCommand(
            words,
            widget.languageCode,
            currentRole: appState.activeRole,
          );
          final double asrConf = (result.hasConfidenceRating && result.confidence > 0)
              ? result.confidence
              : 0.85;

          // Only process when ASR reaches finalResult or when a simple navigation command is spoken alone
          final isSimpleNav = (intent.intent == VoiceIntentType.navigateHome ||
                  intent.intent == VoiceIntentType.navigateBookings ||
                  intent.intent == VoiceIntentType.navigateProfile ||
                  intent.intent == VoiceIntentType.switchRole) &&
              words.split(' ').length <= 2;

          if (result.finalResult || isSimpleNav) {
            _handleSpeechResult(words, asrConfidence: asrConf);
          }
        },
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
    }
  }

  void _handleSpeechResult(String text, {double asrConfidence = 0.85}) {
    if (_processed) return;
    _processed = true;

    _speech.stop();
    if (mounted) setState(() => _isListening = false);

    final appState = context.read<AppState>();
    // Contextual intent resolution: ÃŽ = arg max P(Ik | ASR(S), L, R)
    final intentResult = VoiceAssistantService.parseCommand(
      text,
      widget.languageCode,
      currentRole: appState.activeRole,
    );

    // Formula (1) & (2): Error count k evaluation
    // If CASR < 0.65 or CNLU < 0.70, internal error count k increments.
    // Upon k >= 2: Mode = Voice Assistance (if k < 2) | Icon Manual (if k >= 2)
    final double casr = asrConfidence;
    final double cnlu = intentResult.confidence;

    if (casr < 0.65 || cnlu < 0.70 || intentResult.intent == VoiceIntentType.unknown) {
      appState.recordVoiceFailure(); // k increments
    } else {
      appState.resetVoiceFailures(); // success, reset k = 0
    }

    // Role switch handling directly inside overlay
    if (intentResult.intent == VoiceIntentType.switchRole && intentResult.targetRole != null) {
      appState.setActiveRole(intentResult.targetRole!);
    }

    // Capture callback and nav before popping (context becomes invalid after pop)
    final onIntent = widget.onIntentRecognized;

    // 1. Pop modal sheet â€” dismiss first, then navigate so parent setState runs correctly
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // 2. Navigate AFTER the sheet is fully dismissed (next frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onIntent(intentResult);
    });

    // 3. Play spoken feedback TTS
    Future.microtask(() async {
      await _tts.setLanguage(widget.languageCode);
      await _tts.speak(intentResult.feedbackMessage);
    });
  }

  void _manualStop() {
    if (_liveText.trim().isNotEmpty) {
      _handleSpeechResult(_liveText);
    } else if (_isListening) {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.spatial_audio_off_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'à®•à¯à®°à®²à¯ à®µà®´à®¿à®¨à®Ÿà®¤à¯à®¤à®²à¯ / Voice Command',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status text
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Live transcription
            if (_liveText.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Text(
                  '"$_liveText"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),

            // Mic Button
            GestureDetector(
              onTap: _manualStop,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, child) => Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? AppColors.error : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppColors.error : AppColors.primary).withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sample commands hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: const [
                  Text(
                    'ðŸ’¡ à®•à¯à®°à®²à¯ à®•à®Ÿà¯à®Ÿà®³à¯ˆà®•à®³à¯ / Sample Commands:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'â€¢ "à®Ÿà®¿à®°à®¾à®•à¯à®Ÿà®°à¯ à®µà¯‡à®£à¯à®Ÿà¯à®®à¯ 2 à®à®•à¯à®•à®°à¯" (Smart Book)\nâ€¢ "à®Ÿà®¿à®°à®¾à®•à¯à®Ÿà®°à¯" à®…à®²à¯à®²à®¤à¯ "à®¤à¯‡à®Ÿà¯" (Search)\nâ€¢ "à®Žà®©à¯ à®Žà®¨à¯à®¤à®¿à®°à®™à¯à®•à®³à¯" (Owner mode)\nâ€¢ "à®µà®¾à®Ÿà®•à¯ˆà®•à¯à®•à¯" (Farmer mode)\nâ€¢ "à®µà®°à¯à®®à®¾à®©à®®à¯" (Earnings)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
