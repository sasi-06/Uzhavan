import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dirty_hands_gesture_wrapper.dart';
import '../../core/widgets/shake_detector_wrapper.dart';
import '../../core/widgets/global_voice_overlay.dart';
import '../../core/widgets/mic_button.dart';
import '../../core/widgets/role_switcher_widget.dart';
import '../../core/services/voice_assistant_service.dart';
import 'owner_machines_screen.dart';
import 'owner_bookings_screen.dart';
import 'owner_earnings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../agent/agent_booking_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});
  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _index = 0;
  void _goTo(int i) => setState(() => _index = i);

  void _onVoiceIntent(VoiceIntentResult result) {
    if (result.intent == VoiceIntentType.switchRole &&
        result.targetRole != null) {
      context.read<AppState>().setActiveRole(result.targetRole!);
      return;
    }

    if (result.intent == VoiceIntentType.openAiAgent || result.intent == VoiceIntentType.voiceBook) {
      final speech = result.extractedQuery ?? result.originalSpeech;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AgentBookingScreen(initialSpeech: speech)),
      );
      return;
    }

    switch (result.intent) {
      case VoiceIntentType.navigateHome:
      case VoiceIntentType.listMyMachine:
        _goTo(0);
        break;
      case VoiceIntentType.navigateBookings:
      case VoiceIntentType.acceptBooking:
      case VoiceIntentType.declineBooking:
      case VoiceIntentType.checkBookingStatus:
        _goTo(1);
        break;
      case VoiceIntentType.checkEarnings:
        _goTo(2);
        break;
      case VoiceIntentType.navigateProfile:
        _goTo(3);
        break;
      case VoiceIntentType.searchMachine:
      case VoiceIntentType.bookMachine:
        context.read<AppState>().setActiveRole('farmer');
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

  static const _screens = [
    OwnerMachinesScreen(),
    OwnerBookingsScreen(),
    OwnerEarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 3),
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
                    child: const Icon(
                      Icons.build_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Uzhavan Owner',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
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
          child: IndexedStack(index: _index, children: _screens),
        ),
      ),
      bottomNavigationBar: _OwnerBottomNav(
        index: _index,
        onTap: (i) {
          if (i == 4) {
            _openMic();
            return;
          }
          _goTo(i);
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: MicButton(onPressed: _openMic),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _OwnerBottomNav extends StatelessWidget {
  const _OwnerBottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.agriculture_rounded,
                label: 'எந்திரங்கள்',
                active: index == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.event_note_rounded,
                label: 'முன்பதிவு',
                active: index == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 60), // Center space for Mic FAB
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'வருமானம்',
                active: index == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'சுயவிவரம்',
                active: index == 3,
                onTap: () => onTap(3),
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
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: active ? 10 : 4, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.ownerAccent.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? AppColors.ownerAccent : AppColors.textSecondary,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? AppColors.ownerAccent : AppColors.textSecondary,
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
