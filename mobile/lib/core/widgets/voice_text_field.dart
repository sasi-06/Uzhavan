import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme/app_colors.dart';
import '../utils/speech_manager.dart';


/// A text field that supports both manual typing AND voice input.
/// Tap the mic icon (right side) to speak — fills the field automatically.
/// Works on Android, iOS, and Chrome.
class VoiceTextField extends StatefulWidget {
  const VoiceTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.prefixWidget,
    this.languageCode = 'ta-IN',
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int? maxLength;
  final Widget? prefixWidget;
  final String languageCode;
  final bool enabled;

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = SpeechManager.instance;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _liveWords = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      // Speech not available on this platform/browser
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.white),
              SizedBox(width: 8),
              Text('Microphone not available. Please type manually.'),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
      return;
    }

    if (_isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      setState(() { _isListening = false; _liveWords = ''; });
      return;
    }

    // Stop speech recognition globally if any instance is listening and wait 100ms for resources to release
    if (_speech.isListening) {
      try {
        await _speech.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    }

    setState(() { _isListening = true; _liveWords = ''; });

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: widget.languageCode,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          if (!mounted) return;
          setState(() => _liveWords = result.recognizedWords);
          if (result.finalResult) {
            widget.controller.text = result.recognizedWords;
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );
            setState(() { _isListening = false; _liveWords = ''; });
          }
        },
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      if (mounted) {
        setState(() { _isListening = false; _liveWords = ''; });
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label row with listening badge ──────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (_isListening)
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: _pulseAnim.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.error.withAlpha(80)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic, color: AppColors.error, size: 12),
                        SizedBox(width: 4),
                        Text('Listening…',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Text field with mic as suffixIcon ───────────────────
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _isListening ? AppColors.primary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: _isListening && _liveWords.isNotEmpty
                ? _liveWords
                : widget.hint,
            hintStyle: TextStyle(
              color: _isListening && _liveWords.isNotEmpty
                  ? AppColors.primary.withAlpha(200)
                  : Colors.grey.shade400,
              fontStyle: _isListening && _liveWords.isNotEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              fontWeight: _isListening && _liveWords.isNotEmpty
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
            counterText: '',
            prefixIcon: widget.prefixWidget ??
                Icon(widget.icon, color: AppColors.primary, size: 22),
            // ── Mic button as suffixIcon ────────────────────────
            suffixIcon: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.error
                      : AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale: _isListening ? _pulseAnim.value : 1.0,
                    child: Icon(
                      _isListening
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      color:
                          _isListening ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            filled: true,
            fillColor: _isListening
                ? AppColors.primary.withAlpha(8)
                : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: _isListening
                  ? const BorderSide(color: AppColors.error, width: 2)
                  : BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),

        // ── Live transcription preview ──────────────────────────
        if (_isListening && _liveWords.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _liveWords,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
