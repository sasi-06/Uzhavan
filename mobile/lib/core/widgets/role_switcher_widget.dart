import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/tts_service.dart';

class RoleSwitcherWidget extends StatelessWidget {
  const RoleSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final activeRole = state.activeRole;
    final isOwner = activeRole == 'owner';
    final lang = state.user?.preferredLanguage ?? 'ta';

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Renting (Farmer) Button
          GestureDetector(
            onTap: () {
              if (isOwner) {
                state.setActiveRole('farmer');
                final msg = lang == 'ta'
                    ? 'வாடகைக்கு பகுதிக்கு மாற்றப்பட்டது'
                    : 'Switched to Renting mode';
                TTSService.speak(msg, lang: lang);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isOwner ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: !isOwner
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.agriculture_rounded,
                    size: 15,
                    color: !isOwner ? AppColors.primary : Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'வாடகைக்கு',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: !isOwner ? AppColors.primary : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // My Machines (Owner) Button
          GestureDetector(
            onTap: () {
              if (!isOwner) {
                state.setActiveRole('owner');
                final msg = lang == 'ta'
                    ? 'என் எந்திரங்கள் பகுதிக்கு மாற்றப்பட்டது'
                    : 'Switched to My Machines mode';
                TTSService.speak(msg, lang: lang);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOwner ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isOwner
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.build_rounded,
                    size: 14,
                    color: isOwner ? AppColors.ownerAccent : Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'என் எந்திரங்கள்',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isOwner ? AppColors.ownerAccent : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
