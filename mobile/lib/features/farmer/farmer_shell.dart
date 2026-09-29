import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/providers/accessibility_provider.dart';
import '../../core/theme/accessibility_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dirty_hands_gesture_wrapper.dart';
import '../../core/widgets/shake_detector_wrapper.dart';
import '../../core/widgets/global_voice_overlay.dart';
import '../../core/widgets/mic_button.dart';
import '../../core/widgets/page_voice_reader_button.dart';
import '../../core/widgets/role_switcher_widget.dart';
import '../../core/services/voice_assistant_service.dart';
import '../../core/services/voice_booking_parser.dart';
import '../../features/voice_booking/voice_booking_sheet.dart';
import '../agent/agent_booking_screen.dart';
import 'farmer_home_screen.dart';
import 'farmer_bookings_screen.dart';
import '../../features/profile/profile_screen.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({super.key});
  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  void _onVoiceIntent(VoiceIntentResult result) {
    if (result.intent == VoiceIntentType.switchRole &&
        result.targetRole != null) {
      context.read<AppState>().setActiveRole(result.targetRole!);
      return;
    }

    // ── AI Conversational Booking Agent (Powered by On-Device AI) ─────────
    if (result.intent == VoiceIntentType.openAiAgent) {
      final speech = result.extractedQuery ?? result.originalSpeech;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AgentBookingScreen(initialSpeech: speech)),
      );
      return;
    }

    // ── Voice Smart Booking ────────────────────────────────────────────────
    if (result.intent == VoiceIntentType.voiceBook) {
      final rawText = result.extractedQuery ?? result.originalSpeech;
      final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
      final parsed = VoiceBookingParser.tryParse(rawText, lang);
      if (parsed != null) {
        VoiceBookingSheet.show(context, parsed);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AgentBookingScreen(initialSpeech: rawText)),
        );
      }
      return;
    }

    // ── Machine Search ─────────────────────────────────────────────────────
    if (result.intent == VoiceIntentType.searchMachine) {
      final query = (result.extractedQuery ?? result.originalSpeech).toLowerCase().trim();
      String? matchedType;

      const keywords = {
        'tractor': ['டிராக்டர்', 'tractor', 'ट्रैक्टर', 'ట్రాక్టర్'],
        'harvester': ['அறுவடை', 'harvester', 'हार्वेस्टर', 'హార్వెస్టర్', 'கம்பைன்'],
        'plough': ['கலப்பை', 'ஏர்', 'plough', 'plow', 'हल', 'నాగలి'],
        'seeder': ['விதைப்பான்', 'seeder', 'सीडर', 'సీడర్'],
        'sprayer': ['தெளிப்பான்', 'sprayer', 'स्प्रेयर', 'స్ప్రేయర్'],
        'rotavator': ['ரோட்டவேட்டர்', 'rotavator', 'ரோட்டோவேட்டர்'],
      };

      for (final entry in keywords.entries) {
        if (entry.value.any((k) => query.contains(k))) {
          matchedType = entry.key;
          break;
        }
      }

      context.read<AppState>().setVoiceSearchFilter(matchedType);
      _goTo(0);
      return;
    }

    switch (result.intent) {
      case VoiceIntentType.navigateHome:
      case VoiceIntentType.navigateSearch:
        context.read<AppState>().setVoiceSearchFilter(null);
        _goTo(0);
        break;
      case VoiceIntentType.navigateBookings:
      case VoiceIntentType.checkBookingStatus:
      case VoiceIntentType.cancelBooking:
      case VoiceIntentType.bookMachine:
        _goTo(1);
        break;
      case VoiceIntentType.navigateProfile:
        _goTo(3);
        break;
      case VoiceIntentType.listMyMachine:
      case VoiceIntentType.checkEarnings:
      case VoiceIntentType.acceptBooking:
      case VoiceIntentType.declineBooking:
        context.read<AppState>().setActiveRole('owner');
        break;
      default:
        break;
    }
  }

  void _openMic() {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    final code = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN';
    GlobalVoiceOverlay.show(
      context,
      languageCode: code,
      onIntentRecognized: _onVoiceIntent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    final isHC = acc.isHighContrast;
    final bgColor = AccessibilityTheme.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            gradient: isHC ? null : AppColors.brandGradient,
            color: isHC ? AccessibilityTheme.sunlightCard : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.agriculture_rounded,
                      color: isHC ? AccessibilityTheme.sunlightYellow : Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uzhavan',
                    style: TextStyle(
                      color: isHC ? AccessibilityTheme.sunlightYellow : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RoleSwitcherWidget(),
                      ),
                    ),
                  ),
                  // 🔊 Page Audio Reader Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const PageVoiceReaderButton(
                      textToRead: 'உழவன் வேளாண் எந்திர வாடகை செயலி. டிராக்டர், அறுவடை எந்திரம் வாடகைக்கு எடுக்க குரல் மூலம் ஆணையிடலாம்.',
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ShakeDetectorWrapper(
        onShake: _openMic,
        child: DirtyHandsGestureWrapper(
          onGestureTriggered: _openMic,
          child: IndexedStack(
            index: _index == 2 ? 0 : (_index > 2 ? _index - 1 : _index),
            children: const [
              FarmerHomeScreen(),
              FarmerBookingsScreen(),
              ProfileScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) {
          if (i == 2) {
            _openMic();
            return;
          }
          _goTo(i);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Tooltip(
          message: 'Hold for AI Agent',
          child: GestureDetector(
            onLongPress: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgentBookingScreen()),
            ),
            child: MicButton(onPressed: _openMic),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    final isHC = acc.isHighContrast;
    final primaryColor = AccessibilityTheme.getPrimaryColor(context);

    return Container(
      decoration: BoxDecoration(
        color: isHC ? AccessibilityTheme.sunlightCard : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: BottomAppBar(
        color: isHC ? AccessibilityTheme.sunlightCard : Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'முகப்பு',
                active: index == 0,
                onTap: () => onTap(0),
                primaryColor: primaryColor,
                isHC: isHC,
              ),
              _NavItem(
                icon: Icons.event_note_rounded,
                label: 'முன்பதிவு',
                active: index == 1,
                onTap: () => onTap(1),
                primaryColor: primaryColor,
                isHC: isHC,
              ),
              const SizedBox(width: 60), // Center space for elevated Mic FAB
              _NavItem(
                icon: Icons.person_rounded,
                label: 'சுயவிவரம்',
                active: index == 3,
                onTap: () => onTap(3),
                primaryColor: primaryColor,
                isHC: isHC,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.primaryColor,
    required this.isHC,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isHC;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isHC ? Colors.grey.shade400 : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: active ? 12 : 6, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? (isHC ? Colors.white12 : AppColors.primary.withValues(alpha: 0.10))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: active ? primaryColor : inactiveColor,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? primaryColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
