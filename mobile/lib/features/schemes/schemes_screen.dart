import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/scheme_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/repositories/schemes_repository.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import 'scheme_detail_sheet.dart';

class SchemesScreen extends StatefulWidget {
  final String? initialRole; // 'FARMER' or 'MACHINE_OWNER'

  const SchemesScreen({super.key, this.initialRole});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  final SchemesRepository _repo = SchemesRepository();
  final TtsService _tts = TtsService();

  late String _activeRole;
  String _selectedLanguage = 'ta';
  String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _activeRole = widget.initialRole ?? (appState.activeRole == 'owner' ? 'MACHINE_OWNER' : 'FARMER');
    _selectedLanguage = appState.user?.preferredLanguage ?? 'ta';
    if (!['ta', 'te', 'hi', 'en'].contains(_selectedLanguage)) {
      _selectedLanguage = 'ta';
    }
  }

  void _speakSummary(SchemeModel scheme) async {
    final code = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN', 'en': 'en-IN'}[_selectedLanguage] ?? 'ta-IN';
    await _tts.setLanguage(code);
    await _tts.speak(scheme.toSpeechText());
  }

  @override
  Widget build(BuildContext context) {
    final uiTexts = {
      'headerTitle': {
        'ta': 'அரசு திட்டங்கள் & மானியங்கள்',
        'te': 'ప్రభుత్వ పథకాలు & రాయితీలు',
        'hi': 'सरकारी योजनाएं एवं सब्सिडी',
        'en': 'Government Schemes & Subsidies',
      },
      'farmerTab': {'ta': 'விவசாயி', 'te': 'రైతు', 'hi': 'किसान', 'en': 'Farmer'},
      'ownerTab': {'ta': 'இயந்திர உரிமையாளர்', 'te': 'యంత్ర యజమాని', 'hi': 'मशीन मालिक', 'en': 'Machine Owner'},
      'all': {'ta': 'அனைத்தும்', 'te': 'అన్నీ', 'hi': 'सभी', 'en': 'All'},
      'subsidy': {'ta': 'மானியம்', 'te': 'సబ్సిడీ', 'hi': 'सब्सिडी', 'en': 'Subsidies'},
      'loan': {'ta': 'கடன்', 'te': 'రుణాలు', 'hi': 'ऋण', 'en': 'Loans'},
      'insurance': {'ta': 'காப்பீடு', 'te': 'బీమా', 'hi': 'बीमा', 'en': 'Insurance'},
      'irrigation': {'ta': 'பாசனம்', 'te': 'నీటిపారుదల', 'hi': 'सिंचाई', 'en': 'Irrigation'},
      'viewDetails': {'ta': 'முழு விவரங்கள்', 'te': 'పూర్తి వివరాలు', 'hi': 'पूर्ण विवरण', 'en': 'View Details'},
      'offlineTag': {'ta': 'அரசு அங்கீகரிக்கப்பட்டது', 'te': 'ప్రభుత్వ గుర్తింపు పొందినది', 'hi': 'सरकारी मान्यता प्राप्त', 'en': 'Govt Certified'},
    };

    String t(String key) => uiTexts[key]?[_selectedLanguage] ?? uiTexts[key]?['en'] ?? key;

    final categories = [
      {'key': 'ALL', 'label': t('all')},
      {'key': 'MACHINERY_SUBSIDY', 'label': t('subsidy')},
      {'key': 'DIRECT_BENEFIT', 'label': 'DBT'},
      {'key': 'LOAN_CREDIT', 'label': t('loan')},
      {'key': 'INSURANCE', 'label': t('insurance')},
      {'key': 'IRRIGATION', 'label': t('irrigation')},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Text(
          t('headerTitle'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Language selector popup
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _selectedLanguage == 'ta'
                        ? 'தமிழ்'
                        : _selectedLanguage == 'te'
                            ? 'తెలుగు'
                            : _selectedLanguage == 'hi'
                                ? 'हिन्दी'
                                : 'English',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (val) => setState(() => _selectedLanguage = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
              PopupMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
              PopupMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Role Selection Tabs (Farmer vs Machine Owner)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _RoleTabButton(
                      title: t('farmerTab'),
                      icon: Icons.grass_rounded,
                      isActive: _activeRole == 'FARMER',
                      onTap: () => setState(() => _activeRole = 'FARMER'),
                    ),
                  ),
                  Expanded(
                    child: _RoleTabButton(
                      title: t('ownerTab'),
                      icon: Icons.agriculture_rounded,
                      isActive: _activeRole == 'MACHINE_OWNER',
                      onTap: () => setState(() => _activeRole = 'MACHINE_OWNER'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Filter Chips
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = _selectedCategory == cat['key'];
                return ChoiceChip(
                  label: Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() => _selectedCategory = cat['key']!),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Schemes Stream List
          Expanded(
            child: StreamBuilder<List<SchemeModel>>(
              stream: _repo.streamSchemes(
                role: _activeRole,
                lang: _selectedLanguage,
                category: _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schemes = snapshot.data ?? [];
                if (schemes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No schemes found in this category',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: schemes.length,
                  itemBuilder: (context, index) {
                    final scheme = schemes[index];
                    return _SchemeCard(
                      scheme: scheme,
                      onSpeak: () => _speakSummary(scheme),
                      onTap: () => SchemeDetailSheet.show(context, scheme),
                      viewDetailsLabel: t('viewDetails'),
                      badgeLabel: t('offlineTag'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleTabButton({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [const BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? AppColors.primary : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeCard extends StatelessWidget {
  final SchemeModel scheme;
  final VoidCallback onSpeak;
  final VoidCallback onTap;
  final String viewDetailsLabel;
  final String badgeLabel;

  const _SchemeCard({
    required this.scheme,
    required this.onSpeak,
    required this.onTap,
    required this.viewDetailsLabel,
    required this.badgeLabel,
  });

  IconData _getCategoryIcon() {
    switch (scheme.category) {
      case 'MACHINERY_SUBSIDY':
        return Icons.agriculture_rounded;
      case 'DIRECT_BENEFIT':
        return Icons.currency_rupee_rounded;
      case 'INSURANCE':
        return Icons.shield_rounded;
      case 'IRRIGATION':
        return Icons.water_drop_rounded;
      case 'LOAN_CREDIT':
        return Icons.account_balance_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: Icon + Subsidy Badge + Audio Speaker
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getCategoryIcon(), color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              scheme.subsidyBadge,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            scheme.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 24),
                      onPressed: onSpeak,
                      tooltip: 'Listen to summary',
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Short description
                Text(
                  scheme.shortDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                // Bottom actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          viewDetailsLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
