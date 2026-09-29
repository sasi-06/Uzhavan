import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/machine_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/machine_type_tile.dart';
import '../../core/widgets/star_rating_widget.dart';
import '../../core/widgets/price_chip.dart';
import '../../core/widgets/global_voice_overlay.dart';
import '../../core/services/voice_assistant_service.dart';
import 'farmer_machine_detail_screen.dart';
import '../owner/add_machine_flow_screen.dart';
import '../agent/agent_booking_screen.dart';
import '../location/screens/location_picker_screen.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});
  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedType;
  List<MachineModel> _machines = [];
  bool _loading = false;
  String? _error;
  late AnimationController _pulseCtrl;
  final TtsService _tts = TtsService();

  static const _types = ['tractor', 'harvester', 'plough', 'seeder', 'sprayer'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _search();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final filter = context.watch<AppState>().voiceSearchFilter;
    if (filter != _selectedType) {
      _selectedType = filter;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search(filter);
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _search([String? type]) async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final s = context.read<AppState>();
      final results = await s.machineRepo.search(
        latitude: s.latitude, longitude: s.longitude, type: type);
      if (mounted) setState(() { _machines = results; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _onTypeSelect(String type) {
    final newType = _selectedType == type ? null : type;
    setState(() => _selectedType = newType);
    _search(newType);
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    _tts.setLanguage({'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN');
    _tts.speak(newType ?? 'அனைத்து எந்திரங்கள்');
  }

  void _openVoiceSearch() {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    final code = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN';

    GlobalVoiceOverlay.show(context, languageCode: code, onIntentRecognized: (result) {
      if (result.intent == VoiceIntentType.searchMachine && result.extractedQuery != null) {
        final query = result.extractedQuery!.toLowerCase().trim();
        String? matchedType;

        // Iterate through all machineTypeLabels to match spoken query
        for (final entry in machineTypeLabels.entries) {
          final typeKey = entry.key;
          final translations = entry.value;
          final matches = translations.values.any((val) => query.contains(val.toLowerCase())) || query.contains(typeKey);
          if (matches) {
            matchedType = typeKey;
            break;
          }
        }

        if (matchedType != null) {
          setState(() => _selectedType = matchedType);
          _search(matchedType);

          final localLabel = machineTypeLabels[matchedType]?[lang] ?? matchedType;
          _tts.setLanguage({'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN');
          _tts.speak('$localLabel தேடப்படுகிறது');
        } else {
          // Speak back that no machine matches the spoken query
          final errorMsg = {
            'ta': 'மன்னிக்கவும், அந்த எந்திர வகை கிடைக்கவில்லை',
            'te': 'క్షమించండి, ఆ యంత్రం రకం కనుగొనబడలేదు',
            'hi': 'क्षमा करें, वह मशीन प्रकार नहीं मिला',
            'en': 'Sorry, that machine type was not found',
          }[lang] ?? 'Sorry, that machine type was not found';

          _tts.setLanguage({'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN');
          _tts.speak(errorMsg);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.user?.preferredLanguage ?? 'ta';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _search(_selectedType),
          child: CustomScrollView(
            slivers: [
              // ── Header & Search Bar ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting + Location + Add Machine Action Button
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE2F3E5), Color(0xFFC8E6C9)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'வணக்கம், ${appState.user?.name ?? 'விவசாயி'} 🙏',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LocationPickerScreen(isFarmer: true)),
                                    );
                                    if (result != null) {
                                      final data = result as Map<String, dynamic>;
                                      appState.setLocation(
                                        data['lat'], data['lng'],
                                        v: data['village'], d: data['district'],
                                      );
                                      _search(_selectedType);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          appState.village != null
                                              ? '${appState.village}, ${appState.district}'
                                              : 'Location: ${appState.latitude.toStringAsFixed(2)}, ${appState.longitude.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final added = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddMachineFlowScreen()),
                              );
                              if (added == true) {
                                _search(_selectedType);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'எந்திரம் சேர்',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Search bar (Typing + Mic)
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A0F172A),
                              blurRadius: 14,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(
                                  hintText: 'எந்திரம் தேடுக... / Search machines',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  fillColor: Colors.transparent,
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    _search(val.trim());
                                  }
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                                onPressed: _openVoiceSearch,
                                tooltip: 'Speak search command',
                                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── AI Agent Banner ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AgentBookingScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF072113), Color(0xFF0F3A22), Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.mintAccent.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '🤖 AI உதவியாளர்',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '24/7 AI',
                                        style: TextStyle(
                                          color: AppColors.mintAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lang == 'ta'
                                      ? 'பேசி எந்திரம் முன்பதிவு செய்யுங்கள்'
                                      : lang == 'te'
                                          ? 'మాట్లాడి యంత్రాన్ని బుక్ చేయండి'
                                          : 'Book a machine by speaking or typing',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Machine Type Tiles ────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Text(
                        'எந்திர வகை / Machine Categories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _types.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => MachineTypeTile(
                          type: _types[i],
                          lang: lang,
                          selected: _selectedType == _types[i],
                          onTap: () => _onTypeSelect(_types[i]),
                          size: 100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Section header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'உங்கள் அருகில் உள்ள எந்திரங்கள்',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      if (_machines.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_machines.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Loading Indicator ─────────────────────────────
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                )
              // ── Error Message ─────────────────────────────────
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _search(_selectedType),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('மீண்டும் முயல்க / Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // ── Machine Empty State ───────────────────────────
              else if (_machines.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.agriculture_rounded, size: 72, color: AppColors.divider),
                        SizedBox(height: 16),
                        Text(
                          'அருகில் எந்திரங்கள் இல்லை',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              // ── Machine Cards ─────────────────────────────────
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _MachineCard(machine: _machines[i]),
                    childCount: _machines.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine});
  final MachineModel machine;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FarmerMachineDetailScreen(machine: machine)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Machine image with rounded corner & aspect
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(21),
                bottomLeft: Radius.circular(21),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 114,
                    height: 136,
                    color: const Color(0xFFF1F5F9),
                    child: machine.photos.isNotEmpty
                        ? Image.network(
                            machine.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.agriculture_rounded,
                              size: 46,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.agriculture_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.starGold),
                          const SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.model ?? machine.type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (machine.operatorIncluded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.engineering_rounded, size: 12, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Operator',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Owner details badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (machine.owner?.name.isNotEmpty == true) ? machine.owner!.name : "உரிமையாளர் / Owner",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.verified_rounded, size: 13, color: AppColors.primary),
                        ],
                      ),
                    ),

                    PriceChip(displayPrice: machine.displayPrice),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                machine.distanceKm != null ? '${machine.distanceKm!.toStringAsFixed(1)} km' : '—',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StarRatingWidget(rating: 4.5, starSize: 13),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
