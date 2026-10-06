import 'package:flutter/material.dart';
import '../../core/models/scheme_model.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/web_url_launcher_stub.dart'
    if (dart.library.html) '../../core/utils/web_url_launcher_web.dart';

class SchemeDetailSheet extends StatefulWidget {
  final SchemeModel scheme;

  const SchemeDetailSheet({super.key, required this.scheme});

  static void show(BuildContext context, SchemeModel scheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SchemeDetailSheet(scheme: scheme),
    );
  }

  @override
  State<SchemeDetailSheet> createState() => _SchemeDetailSheetState();
}

class _SchemeDetailSheetState extends State<SchemeDetailSheet> {
  final TtsService _tts = TtsService();
  bool _isPlaying = false;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _toggleSpeak() async {
    if (_isPlaying) {
      await _tts.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    final lang = widget.scheme.currentLang;
    final code = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN', 'en': 'en-IN'}[lang] ?? 'ta-IN';
    await _tts.setLanguage(code);

    final speechBuffer = StringBuffer();
    speechBuffer.writeln(widget.scheme.title);
    speechBuffer.writeln(widget.scheme.subsidyBadge);
    if (widget.scheme.overview.isNotEmpty) {
      speechBuffer.writeln(widget.scheme.overview);
    }
    if (widget.scheme.benefits.isNotEmpty) {
      speechBuffer.writeln(widget.scheme.benefits.join('. '));
    }

    setState(() => _isPlaying = true);
    await _tts.speak(speechBuffer.toString());
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scheme;
    final lang = s.currentLang;

    final labels = {
      'overview': {'ta': 'திட்ட விளக்கம்', 'te': 'పథకం వివరణ', 'hi': 'योजना का विवरण', 'en': 'Scheme Overview'},
      'benefits': {'ta': 'முக்கிய பலன்கள்', 'te': 'ప్రధాన ప్రయోజనాలు', 'hi': 'प्रमुख लाभ', 'en': 'Key Benefits'},
      'eligibility': {'ta': 'தகுதிகள் (யாரெல்லாம் பெறலாம்)', 'te': 'అర్హతలు', 'hi': 'पात्रता', 'en': 'Eligibility'},
      'documents': {'ta': 'தேவையான ஆவணங்கள்', 'te': 'కావలసిన పత్రాలు', 'hi': 'आवश्यक दस्तावेज', 'en': 'Required Documents'},
      'howToApply': {'ta': 'விண்ணப்பிக்கும் முறை', 'te': 'దరఖాస్తు విధానం', 'hi': 'आवेदन प्रक्रिया', 'en': 'How to Apply'},
      'helpline': {'ta': 'உதவி எண்', 'te': 'సహాయ కేంద్రం', 'hi': 'हेल्पलाइन', 'en': 'Helpline'},
      'applyOnline': {'ta': 'அதிகாரப்பூர்வ தளம்', 'te': 'అధికారిక వెబ్‌సైట్', 'hi': 'आधिकारिक पोर्टल', 'en': 'Official Portal'},
    };

    String t(String key) => labels[key]?[lang] ?? labels[key]?['en'] ?? key;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.subsidyBadge,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Voice audio button
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                        color: _isPlaying ? Colors.red : AppColors.primary,
                        size: 32,
                      ),
                      onPressed: _toggleSpeak,
                      tooltip: 'Listen to scheme details',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content scroll
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Overview
                    if (s.overview.isNotEmpty) ...[
                      _SectionHeader(title: t('overview'), icon: Icons.info_outline_rounded),
                      const SizedBox(height: 8),
                      Text(
                        s.overview,
                        style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Benefits
                    if (s.benefits.isNotEmpty) ...[
                      _SectionHeader(title: t('benefits'), icon: Icons.star_rounded, iconColor: Colors.amber.shade700),
                      const SizedBox(height: 8),
                      ...s.benefits.map((b) => _BulletItem(text: b, icon: Icons.check_circle_rounded, iconColor: Colors.green)),
                      const SizedBox(height: 20),
                    ],

                    // Eligibility
                    if (s.eligibility.isNotEmpty) ...[
                      _SectionHeader(title: t('eligibility'), icon: Icons.people_alt_rounded, iconColor: Colors.blue),
                      const SizedBox(height: 8),
                      ...s.eligibility.map((e) => _BulletItem(text: e, icon: Icons.arrow_right_rounded, iconColor: Colors.blue)),
                      const SizedBox(height: 20),
                    ],

                    // Documents
                    if (s.documentsRequired.isNotEmpty) ...[
                      _SectionHeader(title: t('documents'), icon: Icons.description_rounded, iconColor: Colors.purple),
                      const SizedBox(height: 8),
                      ...s.documentsRequired.map((d) => _BulletItem(text: d, icon: Icons.assignment_turned_in_rounded, iconColor: Colors.purple.shade400)),
                      const SizedBox(height: 20),
                    ],

                    // How to Apply
                    if (s.howToApply.isNotEmpty) ...[
                      _SectionHeader(title: t('howToApply'), icon: Icons.touch_app_rounded, iconColor: Colors.orange),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          s.howToApply,
                          style: TextStyle(fontSize: 14, height: 1.45, color: Colors.orange.shade900),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        if (s.applyUrl.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                              label: Text(
                                t('applyOnline'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              onPressed: () {
                                openWebWindow(s.applyUrl);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opening: ${s.applyUrl}')),
                                );
                              },
                            ),
                          ),
                        if (s.applyUrl.isNotEmpty && s.helpline.isNotEmpty)
                          const SizedBox(width: 12),
                        if (s.helpline.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: AppColors.primary),
                              label: Text(
                                s.helpline,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${t('helpline')}: ${s.helpline}')),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({required this.title, required this.icon, this.iconColor = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;

  const _BulletItem({required this.text, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
