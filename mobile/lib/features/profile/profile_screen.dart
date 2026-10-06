import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/accessibility_provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/accessibility_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/haptic_feedback_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/role_switcher_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accProvider = context.watch<AccessibilityProvider>();
    final user = appState.user;
    final name  = user?.name  ?? '';
    final phone = user?.phone ?? '';
    final lang  = user?.preferredLanguage ?? 'ta';
    final activeRole = appState.activeRole;
    final isOwner = activeRole == 'owner';

    final isHC = accProvider.isHighContrast;
    final primaryColor = isHC ? AccessibilityTheme.sunlightYellow : (isOwner ? AppColors.ownerAccent : AppColors.primary);
    final bgColor = AccessibilityTheme.getBackgroundColor(context);
    final cardColor = AccessibilityTheme.getCardColor(context);
    final textPrimary = AccessibilityTheme.getTextPrimaryColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'சுயவிவரம் / Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [
          // Avatar
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.25),
                  primaryColor.withValues(alpha: 0.10),
                ],
              ),
              border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.person_rounded, size: 54, color: primaryColor),
          ),
          const SizedBox(height: 14),

          // Name & Phone
          Text(
            name.isNotEmpty ? name : 'விவசாயி / User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          Text(phone, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AccessibilityTheme.getTextSecondaryColor(context))),

          const SizedBox(height: 24),

          // 🌟 UZHAVAN ACCESSIBILITY & INCLUSIVITY SHIELD CARD
          _AccessibilitySettingsCard(isOwner: isOwner),
          const SizedBox(height: 16),

          // Role Switch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isHC ? AccessibilityTheme.sunlightYellow : AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('பங்கு மாற்றம் / Active Role', style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            isOwner ? 'என் எந்திரங்கள் (Owner)' : 'வாடகைக்கு (Renting)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(child: RoleSwitcherWidget()),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Info tiles
          _InfoRow(icon: Icons.phone_rounded, value: phone, isOwner: isOwner),
          const SizedBox(height: 12),

          // Emergency Contact Card
          _EmergencyContactCard(user: user, isOwner: isOwner),
          const SizedBox(height: 12),

          // Language selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isHC ? AccessibilityTheme.sunlightYellow : AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.language_rounded, color: primaryColor, size: 28),
                  const SizedBox(width: 14),
                  Text('மொழி / Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                ]),
                const SizedBox(height: 14),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LangBtn(label: 'தமிழ்', code: 'ta', selected: lang == 'ta', isOwner: isOwner, onTap: () {
                        appState.setLanguage('ta');
                        TTSService.speak('தமிழ் தேர்ந்தெடுக்கப்பட்டது', lang: 'ta');
                      }),
                      const SizedBox(width: 8),
                      _LangBtn(label: 'తెలుగు', code: 'te', selected: lang == 'te', isOwner: isOwner, onTap: () {
                        appState.setLanguage('te');
                        TTSService.speak('తెలుగు ఎంచుకోబడింది', lang: 'te');
                      }),
                      const SizedBox(width: 8),
                      _LangBtn(label: 'हिंदी', code: 'hi', selected: lang == 'hi', isOwner: isOwner, onTap: () {
                        appState.setLanguage('hi');
                        TTSService.speak('हिंदी चुनी गई', lang: 'hi');
                      }),
                      const SizedBox(width: 8),
                      _LangBtn(label: 'English', code: 'en', selected: lang == 'en', isOwner: isOwner, onTap: () {
                        appState.setLanguage('en');
                        TTSService.speak('English selected', lang: 'en');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isHC ? AccessibilityTheme.sunlightRed : AppColors.error,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () {
              TTSService.speak('வெளியேறுகிறோம்', lang: 'ta');
              context.read<AppState>().logout();
            },
            icon: const Icon(Icons.logout_rounded, size: 24, color: Colors.white),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('வெளியேறு / Logout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _AccessibilitySettingsCard extends StatelessWidget {
  const _AccessibilitySettingsCard({required this.isOwner});
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessibilityProvider>();
    final isHC = acc.isHighContrast;
    final primaryColor = isHC ? AccessibilityTheme.sunlightYellow : (isOwner ? AppColors.ownerAccent : AppColors.primary);
    final cardColor = AccessibilityTheme.getCardColor(context);
    final textPrimary = AccessibilityTheme.getTextPrimaryColor(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHC ? AccessibilityTheme.sunlightYellow : primaryColor.withAlpha(100),
          width: isHC ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.accessibility_new_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'எளிதான பயன்பாடு / Accessibility Shield',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'வெயில் & குரல் வழிநடத்தல் அமைப்புகள்',
                      style: TextStyle(
                        fontSize: 12,
                        color: AccessibilityTheme.getTextSecondaryColor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // 1. High Contrast Sunlight Mode Switch
          SwitchListTile(
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.wb_sunny_rounded, color: isHC ? AccessibilityTheme.sunlightYellow : Colors.amber.shade700),
            title: Text(
              'சூரிய வெளிச்ச பயன்முறை / High-Contrast Sunlight Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              'அடர்ந்த கருப்பு & தெளிவான மஞ்சள் நிறம் (High Contrast)',
              style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context)),
            ),
            value: acc.isHighContrast,
            onChanged: (val) {
              HapticFeedbackService.selectionClick();
              acc.setHighContrast(val);
            },
          ),

          // 2. Pictogram Mode Switch
          SwitchListTile(
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.grid_view_rounded, color: primaryColor),
            title: Text(
              'படம் சார்ந்த பார்வை / Pictogram-First Mode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              'பெரிய படங்கள் & எழுத்து குறைவான அட்டவணைகள்',
              style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context)),
            ),
            value: acc.isPictogramMode,
            onChanged: (val) {
              HapticFeedbackService.selectionClick();
              acc.setPictogramMode(val);
            },
          ),

          // 3. Dirty Hands Gesture Assist
          SwitchListTile(
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.touch_app_rounded, color: primaryColor),
            title: Text(
              'சேறு/மண் கைகள் உதவி / Dirty-Hands Gesture Assist',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              'திரையை இருமுறை தொட்டால் குரல் வழி திறக்கும்',
              style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context)),
            ),
            value: acc.dirtyHandsMode,
            onChanged: (val) {
              HapticFeedbackService.selectionClick();
              acc.setDirtyHandsMode(val);
            },
          ),

          // 4. Shake to Open Voice Assistant
          SwitchListTile(
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.screen_rotation_alt_rounded, color: primaryColor),
            title: Text(
              'போனை குலுக்கினால் குரல் உதவி / Shake to Open Voice',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              'போனை இருமுறை அசைத்தால்/குலுக்கினால் தானாக மைக் திறக்கும்',
              style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context)),
            ),
            value: acc.shakeToVoice,
            onChanged: (val) {
              HapticFeedbackService.selectionClick();
              acc.setShakeToVoice(val);
            },
          ),

          // 5. Haptic Feedback Toggle
          SwitchListTile(
            activeColor: primaryColor,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(Icons.vibration_rounded, color: primaryColor),
            title: Text(
              'தொடு அதிர்வு / Tactile Haptic Feedback',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            subtitle: Text(
              'பொத்தான்களை தொடும் போது அதிர்வு உணர்வு',
              style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context)),
            ),
            value: acc.hapticFeedbackEnabled,
            onChanged: (val) {
              HapticFeedbackService.selectionClick();
              acc.setHapticFeedback(val);
            },
          ),

          const SizedBox(height: 8),
          // Font Scaling Slider
          Row(
            children: [
              Icon(Icons.format_size_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'எழுத்து அளவு / Font Scale: ${(acc.fontSizeScale * 100).toInt()}%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          Slider(
            activeColor: primaryColor,
            min: 1.0,
            max: 1.5,
            divisions: 5,
            value: acc.fontSizeScale,
            onChanged: (val) => acc.setFontSizeScale(val),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value, required this.isOwner});
  final IconData icon; final String value; final bool isOwner;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AccessibilityTheme.getCardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(children: [
      Icon(icon, color: isOwner ? AppColors.ownerAccent : AppColors.primary, size: 28),
      const SizedBox(width: 14),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AccessibilityTheme.getTextPrimaryColor(context))),
    ]),
  );
}

class _LangBtn extends StatelessWidget {
  const _LangBtn({required this.label, required this.code, required this.selected, required this.isOwner, required this.onTap});
  final String label, code; final bool selected, isOwner; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = isOwner ? AppColors.ownerAccent : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? c : AppColors.divider, width: 2),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppColors.textSecondary,
        )),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({required this.user, required this.isOwner});
  final UserModel? user;
  final bool isOwner;

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: user?.emergencyName ?? '');
    final phoneCtrl = TextEditingController(text: user?.emergencyPhone ?? '');
    final relationCtrl = TextEditingController(text: user?.emergencyRelation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('அவசர தொடர்பு / Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'பெயர் / Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'கைபேசி எண் / Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(labelText: 'உறவு / Relationship'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: isOwner ? AppColors.ownerAccent : AppColors.primary),
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.updateUserEmergencyContact(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                relation: relationCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContact = user?.emergencyName != null && user!.emergencyName!.isNotEmpty;
    final color = isOwner ? AppColors.ownerAccent : AppColors.primary;

    return GestureDetector(
      onTap: () => _showEditDialog(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AccessibilityTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.contact_phone_rounded, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('அவசர தொடர்பு / Emergency Contact',
                      style: TextStyle(fontSize: 12, color: AccessibilityTheme.getTextSecondaryColor(context), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    hasContact
                        ? '${user!.emergencyName} (${user!.emergencyRelation}) - ${user!.emergencyPhone}'
                        : 'அமைக்கப்படவில்லை / Not Configured (Tap to Set)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasContact ? AccessibilityTheme.getTextPrimaryColor(context) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
