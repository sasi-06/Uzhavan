import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tts_service.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import 'mic_button.dart';

class VoiceConfirmationDialog extends StatefulWidget {
  const VoiceConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.spokenMessage,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String? spokenMessage;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    String? spokenMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceConfirmationDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
        spokenMessage: spokenMessage,
      ),
    );
  }

  @override
  State<VoiceConfirmationDialog> createState() => _VoiceConfirmationDialogState();
}

class _VoiceConfirmationDialogState extends State<VoiceConfirmationDialog> {
  @override
  void initState() {
    super.initState();
    _readAloud();
  }

  void _readAloud() {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    final text = widget.spokenMessage ?? '${widget.title}. ${widget.message}';
    TTSService.speak(text, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'உறுதிப்படுத்தல் / Confirmation',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                onPressed: _readAloud,
                tooltip: 'Listen again',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.message,
              style: const TextStyle(fontSize: 17, height: 1.4, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Decline Button (Red / 56dp tall)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      TTSService.stop();
                      Navigator.pop(context, false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 20),
                        SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('வேண்டாம் / NO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Confirm Button (Green / 56dp tall)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      TTSService.stop();
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(widget.actionLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
