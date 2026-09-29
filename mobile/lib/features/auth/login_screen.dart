import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _phoneFocus = FocusNode();
  final _otpFocus   = FocusNode();
  final TtsService _tts = TtsService();

  bool    _otpSent = false;
  bool    _loading = false;
  String? _devOtp;
  String? _error;
  String  _lang   = 'ta'; // ta · te · hi · en

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── localized strings ──────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> _l10n = {
    'ta': {
      'welcome':      'வணக்கம்!',
      'subtitle':     'உழவன் — விவசாய எந்திர வாடகை',
      'phone_label':  'உங்கள் கைபேசி எண்',
      'phone_hint':   '9876543210',
      'send_otp':     'OTP அனுப்பு',
      'otp_label':    'OTP குறியீடு',
      'otp_sent':     'உங்கள் எண்ணுக்கு OTP அனுப்பப்பட்டது',
      'login':        'உள்நுழை',
      'change':       'எண் மாற்று',
      'new_user':     'புதியவரா? கணக்கு தொடங்க',
      'error_phone':  '10 இலக்க கைபேசி எண் உள்ளிடவும்',
      'error_otp':    '6 இலக்க OTP உள்ளிடவும்',
      'speak_welcome':'வணக்கம்! உங்கள் கைபேசி எண்ணை உள்ளிடவும்.',
    },
    'te': {
      'welcome':      'నమస్కారం!',
      'subtitle':     'ఉళవన్ — వ్యవసాయ యంత్ర అద్దె',
      'phone_label':  'మీ మొబైల్ నంబర్',
      'phone_hint':   '9876543210',
      'send_otp':     'OTP పంపండి',
      'otp_label':    'OTP కోడ్',
      'otp_sent':     'మీ నంబర్‌కు OTP పంపబడింది',
      'login':        'లాగిన్',
      'change':       'నంబర్ మార్చు',
      'new_user':     'కొత్తవారా? ఖాతా తెరవండి',
      'error_phone':  '10 అంకెల నంబర్ నమోదు చేయండి',
      'error_otp':    '6 అంకెల OTP నమోదు చేయండి',
      'speak_welcome':'నమస్కారం! మీ మొబైల్ నంబర్ నమోదు చేయండి.',
    },
    'hi': {
      'welcome':      'नमस्ते!',
      'subtitle':     'उझवन — कृषि मशीन किराया',
      'phone_label':  'आपका मोबाइल नंबर',
      'phone_hint':   '9876543210',
      'send_otp':     'OTP भेजें',
      'otp_label':    'OTP कोड',
      'otp_sent':     'आपके नंबर पर OTP भेजा गया',
      'login':        'लॉग इन',
      'change':       'नंबर बदलें',
      'new_user':     'नए हैं? खाता बनाएं',
      'error_phone':  '10 अंकों का नंबर दर्ज करें',
      'error_otp':    '6 अंकों का OTP दर्ज करें',
      'speak_welcome':'नमस्ते! अपना मोबाइल नंबर दर्ज करें।',
    },
    'en': {
      'welcome':      'Welcome back!',
      'subtitle':     'Uzhavan — Farm Machine Rental',
      'phone_label':  'Mobile Number',
      'phone_hint':   '9876543210',
      'send_otp':     'Send OTP',
      'otp_label':    'OTP Code',
      'otp_sent':     'OTP sent to your number',
      'login':        'Login',
      'change':       'Change number',
      'new_user':     'New here? Create Account',
      'error_phone':  'Enter a valid 10-digit number',
      'error_otp':    'Enter the 6-digit OTP',
      'speak_welcome':'Welcome! Please enter your mobile number.',
    },
  };

  String _t(String key) => _l10n[_lang]?[key] ?? _l10n['en']![key]!;

  // ── language meta ──────────────────────────────────────────────────────────
  static const _langs = [
    {'code': 'ta', 'label': 'த',  'name': 'தமிழ்',    'ttsCode': 'ta-IN'},
    {'code': 'te', 'label': 'తె', 'name': 'తెలుగు',   'ttsCode': 'te-IN'},
    {'code': 'hi', 'label': 'हि', 'name': 'हिंदी',    'ttsCode': 'hi-IN'},
    {'code': 'en', 'label': 'En', 'name': 'English',  'ttsCode': 'en-IN'},
  ];

  String get _ttsCode => _langs.firstWhere((l) => l['code'] == _lang)['ttsCode']!;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Welcome TTS after a short delay (disabled on Web to prevent browser autoplay error)
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _tts.setLanguage(_ttsCode);
        _tts.speak(_t('speak_welcome'));
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose(); _otpCtrl.dispose();
    _phoneFocus.dispose(); _otpFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _switchLang(String code) {
    setState(() { _lang = code; _error = null; });
    final lang = _langs.firstWhere((l) => l['code'] == code);
    _tts.setLanguage(lang['ttsCode']!);
    _tts.speak(_t('speak_welcome'));
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = _t('error_phone'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final otp = await context.read<AppState>().sendOtp(phone);
      setState(() { _otpSent = true; _devOtp = otp; });
      _animCtrl..reset()..forward();
      Future.delayed(const Duration(milliseconds: 300), () => _otpFocus.requestFocus());
      _tts.setLanguage(_ttsCode);
      _tts.speak(_t('otp_sent'));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    if (_otpCtrl.text.trim().length < 6) {
      setState(() => _error = _t('error_otp'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppState>().login(
        phone: _phoneCtrl.text.trim(),
        otp: _otpCtrl.text.trim(),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.forestDark,
      body: Stack(
        children: [
          // ── Layered ambient background ──────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF061A0F),
                  Color(0xFF0D3820),
                  Color(0xFF14532D),
                  Color(0xFFF1F5F9),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Decorative ambient glowing orbs ──────────────────────
          Positioned(
            top: -60, right: -60,
            child: _GlowOrb(size: 240, color: AppColors.primaryLight.withValues(alpha: 0.15)),
          ),
          Positioned(
            top: 140, left: -60,
            child: _GlowOrb(size: 180, color: AppColors.mintAccent.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: size.height * 0.35, right: -40,
            child: _GlowOrb(size: 140, color: AppColors.primary.withValues(alpha: 0.08)),
          ),

          // ── Main Content ─────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // ── Language selector (Floating frosted pill bar) ───
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _langs.map((l) {
                              final isSelected = _lang == l['code'];
                              return GestureDetector(
                                onTap: () => _switchLang(l['code']!),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.18),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    l['label']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Brand Logo Emblem ────────────────────────
                      Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Color(0xFFE2F3E5)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.agriculture_rounded,
                              size: 52,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // App name & subtitle
                      const Text(
                        'Uzhavan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _t('subtitle'),
                          key: ValueKey(_lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Elevated Floating Card ───────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F0F172A),
                              blurRadius: 32,
                              spreadRadius: 0,
                              offset: Offset(0, 14),
                            ),
                            BoxShadow(
                              color: Color(0x0A0F172A),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Card heading
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _otpSent ? _t('otp_label') : _t('welcome'),
                                key: ValueKey('${_lang}_$_otpSent'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _otpSent
                                    ? '${_t('otp_sent')}: +91 ${_phoneCtrl.text.trim()}'
                                    : _t('subtitle'),
                                key: ValueKey('sub_${_lang}_$_otpSent'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // ── Phone field ──────────────────────
                            _FieldLabel(_t('phone_label')),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneCtrl,
                              focusNode: _phoneFocus,
                              keyboardType: TextInputType.phone,
                              enabled: !_otpSent,
                              maxLength: 10,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: _t('phone_hint'),
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                                    ),
                                  ),
                                  child: const Text(
                                    '+91',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),

                            // ── OTP field (animated) ─────────────
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _otpSent
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 16),
                                        _FieldLabel(_t('otp_label')),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _otpCtrl,
                                          focusNode: _otpFocus,
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 10,
                                            color: AppColors.primary,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: '• • • • • •',
                                            counterText: '',
                                            helperText: _devOtp != null ? '🔑 Dev OTP: $_devOtp' : null,
                                            helperStyle: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: _loading
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _otpSent = false;
                                                      _otpCtrl.clear();
                                                      _devOtp = null;
                                                    });
                                                  },
                                            icon: const Icon(Icons.edit_rounded, size: 14),
                                            label: Text(
                                              _t('change'),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // ── Error Alert ───────────────────────
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _error != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: const TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 22),

                            // ── Primary Action Button ─────────────
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.38),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : (_otpSent ? _login : _sendOtp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(_otpSent ? Icons.login_rounded : Icons.send_rounded, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            _otpSent ? _t('login') : _t('send_otp'),
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Register Link (Frosted Glass Pill) ───────
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            key: ValueKey(_lang),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _t('new_user'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Role Hint Cards ──────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _RoleHintCard(
                              icon: Icons.person_rounded,
                              label: 'Farmer',
                              sub: 'வாடகைக்கு எடுக்க',
                              color: AppColors.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RoleHintCard(
                              icon: Icons.agriculture_rounded,
                              label: 'Owner',
                              sub: 'எந்திரங்களை வாடகைக்கு விட',
                              color: AppColors.ownerLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}

class _RoleHintCard extends StatelessWidget {
  const _RoleHintCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
