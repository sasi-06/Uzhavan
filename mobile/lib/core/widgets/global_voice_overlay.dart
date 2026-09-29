import 'dart:async';
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

  static bool _isShowing = false;
  static bool get isShowing => _isShowing;

  static void show(
    BuildContext context, {
    required String languageCode,
    required ValueChanged<VoiceIntentResult> onIntentRecognized,
    bool useRootNavigator = true,
  }) {
    if (_isShowing) return;
    _isShowing = true;
    showModalBottomSheet(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlobalVoiceOverlay(
        languageCode: languageCode,
        onIntentRecognized: onIntentRecognized,
      ),
    ).whenComplete(() {
      _isShowing = false;
    });
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
  String _statusText = 'மைக் அழுத்தி பேசுங்கள் / Speak your request';
  Timer? _silenceDebounce;

  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.15).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _initSpeechAndStart();
  }

  @override
  void dispose() {
    _silenceDebounce?.cancel();
    _animCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeechAndStart() async {
    final appState = context.read<AppState>();
    if (appState.consecutiveVoiceFailures >= 2) {
      if (mounted) {
        setState(() {
          _statusText = 'தொட்டுப் பயன்படுத்தவும் / Tap command below';
        });
      }
      appState.resetVoiceFailures();
    }

    try {
      final available = await _speech.initialize(
        onError: (e) {
          debugPrint('Speech init error: ${e.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
            });
          }
        },
        onStatus: (s) {
          debugPrint('Speech status: $s');
          if ((s == 'done' || s == 'notListening') && mounted) {
            if (!_processed && _liveText.trim().isNotEmpty) {
              _handleSpeechResult(_liveText);
            } else if (mounted) {
              setState(() {
                _isListening = false;
                if (_liveText.isEmpty) {
                  _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
                }
              });
            }
          }
        },
      );
      if (mounted) {
        if (available) {
          _startListening();
        } else {
          setState(() {
            _isListening = false;
            _statusText = 'மைக் கிடைக்கவில்லை / Tap sample command below';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
        });
      }
    }
  }

  Future<void> _startListening() async {
    _silenceDebounce?.cancel();

    if (!_speech.isAvailable) {
      await _speech.initialize(
        onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
        onStatus: (s) {
          if ((s == 'done' || s == 'notListening') && mounted) {
            if (!_processed && _liveText.trim().isNotEmpty) {
              _handleSpeechResult(_liveText);
            } else if (mounted) {
              setState(() {
                _isListening = false;
                if (_liveText.isEmpty) {
                  _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
                }
              });
            }
          }
        },
      );
    }

    _liveText = '';
    _processed = false;
    setState(() {
      _isListening = true;
      _statusText = 'கேட்கிறது... இப்போது பேசுங்கள் / Listening...';
    });

    try {
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty && mounted) {
            setState(() {
              _liveText = words;
              _statusText = 'கேட்கிறது... / Hearing you...';
            });

            if (result.finalResult) {
              _silenceDebounce?.cancel();
              _handleSpeechResult(words);
            } else {
              _silenceDebounce?.cancel();
              final isTractorQuery = words.toLowerCase().contains('tractor') ||
                  words.toLowerCase().contains('டிராக்டர்') ||
                  words.toLowerCase().contains('ஏக்கர்');
              final debounceMs = isTractorQuery ? 700 : 1100;

              _silenceDebounce = Timer(Duration(milliseconds: debounceMs), () {
                if (mounted && !_processed && _liveText.trim().isNotEmpty) {
                  _handleSpeechResult(_liveText);
                }
              });
            }
          }
        },
        localeId: widget.languageCode,
        listenFor: const Duration(seconds: 14),
        pauseFor: const Duration(seconds: 4),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
        });
      }
    }
  }

  void _handleSpeechResult(String spokenText) async {
    if (_processed) return;
    _processed = true;
    _silenceDebounce?.cancel();

    await _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }

    final cleaned = spokenText.trim();
    if (cleaned.isEmpty) {
      if (mounted) {
        setState(() {
          _statusText = 'புரியவில்லை, மீண்டும் பேசவும் / Speak again';
          _processed = false;
        });
      }
      return;
    }

    final appState = context.read<AppState>();
    final intentResult = VoiceAssistantService.parseCommand(
      cleaned,
      widget.languageCode,
      currentRole: appState.activeRole,
    );

    double asrConfidence = 0.90;
    try {
      if (_speech.lastRecognizedWords.isNotEmpty) {
        asrConfidence = 0.88;
      }
    } catch (_) {}

    final double casr = asrConfidence;
    final double cnlu = intentResult.confidence;

    if (casr < 0.65 || cnlu < 0.70 || intentResult.intent == VoiceIntentType.unknown) {
      appState.recordVoiceFailure();
    } else {
      appState.resetVoiceFailures();
    }

    if (intentResult.intent == VoiceIntentType.switchRole && intentResult.targetRole != null) {
      appState.setActiveRole(intentResult.targetRole!);
    }

    final onIntent = widget.onIntentRecognized;
    final feedback = intentResult.feedbackMessage;
    final lang = widget.languageCode;

    // 1. Close modal sheet cleanly
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // 2. Dispatch intent after sheet has closed so Navigator transitions cleanly
    Future.delayed(const Duration(milliseconds: 200), () {
      onIntent(intentResult);
      _tts.setLanguage(lang);
      _tts.speak(feedback);
    });
  }

  void _onMicTap() {
    if (_liveText.trim().isNotEmpty) {
      _handleSpeechResult(_liveText);
    } else if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _stopListening() async {
    _silenceDebounce?.cancel();
    await _speech.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
        if (_liveText.isEmpty) {
          _statusText = 'பேச மைக் பட்டனை தொடவும் / Tap mic to speak';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A160F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: Color(0x334ADE80), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 18),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.spatial_audio_rounded, color: AppColors.mintAccent, size: 20),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'குரல் வழிநடத்தல் / Voice Command',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _statusText,
                key: ValueKey(_statusText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: _isListening ? AppColors.mintAccent : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Live transcription with instant tap to execute
            if (_liveText.isNotEmpty)
              InkWell(
                onTap: () => _handleSpeechResult(_liveText),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.mintAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, color: AppColors.mintAccent, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '"$_liveText"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.mintAccent, size: 18),
                    ],
                  ),
                ),
              ),

            // Animated Mic Button with Concentric Soundwave Rings
            GestureDetector(
              onTap: _onMicTap,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (ctx, child) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ripple ring
                    if (_isListening)
                      Container(
                        width: 120 * _pulseAnim.value,
                        height: 120 * _pulseAnim.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isListening ? AppColors.error : AppColors.primary).withValues(alpha: 0.12),
                        ),
                      ),
                    // Middle ripple ring
                    if (_isListening)
                      Container(
                        width: 104 * _pulseAnim.value,
                        height: 104 * _pulseAnim.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isListening ? AppColors.error : AppColors.primary).withValues(alpha: 0.22),
                        ),
                      ),
                    // Central Mic Button
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isListening
                              ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                              : [const Color(0xFF22C55E), const Color(0xFF15803D)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.error : AppColors.primary).withValues(alpha: 0.45),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // AI Agent Direct Launch Button
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onIntentRecognized(
                  const VoiceIntentResult(
                    intent: VoiceIntentType.openAiAgent,
                    originalSpeech: 'agent',
                    feedbackMessage: 'உழவன் AI உதவியாளர் திறக்கப்படுகிறது',
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F3A22), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.mintAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      '🤖 AI உழவன் உதவியாளர் / Open AI Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Interactive Sample commands (Tap or Speak)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                children: [
                  const Text(
                    '💡 விரைவு குரல் கட்டளைகள் (பேசலாம் அல்லது தொடலாம்):',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildSampleChip('🚜 டிராக்டர் வேண்டும் 2 ஏக்கர்'),
                      _buildSampleChip('🔍 டிராக்டர் தேடு'),
                      _buildSampleChip('🌾 அறுவடை எந்திரம்'),
                      _buildSampleChip('📅 என் முன்பதிவுகள்'),
                      _buildSampleChip('⚙️ என் எந்திரங்கள்'),
                      _buildSampleChip('💰 வருமானம்'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleChip(String label) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      onPressed: () {
        final clean = label.replaceFirst(RegExp(r'^[^\w\s\u0B80-\u0BFF]+'), '').trim();
        _handleSpeechResult(clean);
      },
    );
  }
}
