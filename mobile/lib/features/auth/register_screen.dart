import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/voice_text_field.dart';


enum _UserRole { farmer, owner }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0=language+role, 1=personal, 2=otp

  final _nameCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _otpCtrl          = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _villageCtrl      = TextEditingController();
  final _districtCtrl     = TextEditingController();
  final _machineModelCtrl = TextEditingController();
  final _machinePriceCtrl = TextEditingController();

  _UserRole _role             = _UserRole.farmer;
  String    _lang             = 'ta';
  String    _machineType      = 'tractor';
  bool      _operatorIncluded = true;
  bool      _loading          = false;
  bool      _obscure          = true;
  String?   _devOtp;
  String?   _error;

  // GPS state
  double?   _regLat;
  double?   _regLng;
  bool      _gpsLoading = false;
  String?   _gpsStatus;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // ── Full multilingual strings ──────────────────────────────────────────────
  static const Map<String, Map<String, String>> _s = {
    'ta': {
      'title':           'கணக்கு தொடங்க',
      'subtitle':        'உழவன் — உழவன் / எந்திர உரிமையாளர்',
      'who':             'நீங்கள் யார்?',
      'who_sub':         'உழவன் தளத்தில் உங்கள் பங்கை தேர்ந்தெடுக்கவும்',
      'farmer':          'விவசாயி',
      'farmer_sub':      'எந்திரங்களை வாடகைக்கு எடுக்கவும்',
      'owner':           'எந்திர உரிமையாளர்',
      'owner_sub':       'எந்திரங்களை வாடகைக்கு கொடுக்கவும்',
      'details':         'உங்கள் விவரங்கள்',
      'details_sub':     'தட்டி எழுதுங்கள் அல்லது 🎤 மூலம் பேசுங்கள்',
      'name':            'முழு பெயர்',
      'name_hint':       'எ.கா. முருகன் செல்வம்',
      'phone':           'கைபேசி எண்',
      'phone_hint':      '9876543210',
      'village':         'ஊர் / நகரம்',
      'village_hint':    'எ.கா. தஞ்சாவூர்',
      'district':        'மாவட்டம்',
      'district_hint':   'எ.கா. தஞ்சாவூர்',
      'password':        'கடவுச்சொல் (விருப்பம்)',
      'password_hint':   '6+ எழுத்துக்கள்',
      'verify':          'OTP சரிபார்க்க',
      'verify_sub':      'உங்கள் எண்ணுக்கு OTP அனுப்பப்பட்டது',
      'otp_label':       'OTP குறியீடு',
      'otp_hint':        '• • • • • •',
      'change':          'எண் மாற்று',
      'next':            'அடுத்து →',
      'submit':          'பதிவு செய் ✓',
      'login':           'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழை',
      'err_name':        'முழு பெயர் உள்ளிடவும்',
      'err_phone':       '10 இலக்க கைபேசி எண் உள்ளிடவும்',
      'err_village':     'ஊர் / நகரம் உள்ளிடவும்',
      'err_district':    'மாவட்டம் உள்ளிடவும்',
      'err_otp':         '6 இலக்க OTP உள்ளிடவும்',
      'step_lang':       'மொழி & பங்கு',
      'step_details':    'விவரங்கள்',
      'step_verify':     'சரிபார்',
    },
    'te': {
      'title':           'ఖాతా సృష్టించు',
      'subtitle':        'ఉళవన్ — రైతు / యంత్రం యజమాని',
      'who':             'మీరు ఎవరు?',
      'who_sub':         'ఉళవన్ వేదికలో మీ పాత్రను ఎంచుకోండి',
      'farmer':          'రైతు',
      'farmer_sub':      'యంత్రాలు అద్దెకు తీసుకోండి',
      'owner':           'యంత్రం యజమాని',
      'owner_sub':       'యంత్రాలు అద్దెకు ఇవ్వండి',
      'details':         'మీ వివరాలు',
      'details_sub':     'టైప్ చేయండి లేదా 🎤 ద్వారా మాట్లాడండి',
      'name':            'పూర్తి పేరు',
      'name_hint':       'ఉదా. రామారావు',
      'phone':           'మొబైల్ నంబర్',
      'phone_hint':      '9876543210',
      'village':         'గ్రామం / పట్టణం',
      'village_hint':    'ఉదా. గుంటూరు',
      'district':        'జిల్లా',
      'district_hint':   'ఉదా. గుంటూరు',
      'password':        'పాస్వర్డ్ (ఐచ్ఛికం)',
      'password_hint':   '6+ అక్షరాలు',
      'verify':          'OTP ధృవీకరించు',
      'verify_sub':      'మీ నంబర్‌కు OTP పంపబడింది',
      'otp_label':       'OTP కోడ్',
      'otp_hint':        '• • • • • •',
      'change':          'నంబర్ మార్చు',
      'next':            'తదుపరి →',
      'submit':          'నమోదు చేయి ✓',
      'login':           'ఇప్పటికే ఖాతా ఉందా? లాగిన్',
      'err_name':        'పూర్తి పేరు నమోదు చేయండి',
      'err_phone':       '10 అంకెల నంబర్ నమోదు చేయండి',
      'err_village':     'గ్రామం నమోదు చేయండి',
      'err_district':    'జిల్లా నమోదు చేయండి',
      'err_otp':         '6 అంకెల OTP నమోదు చేయండి',
      'step_lang':       'భాష & పాత్ర',
      'step_details':    'వివరాలు',
      'step_verify':     'ధృవీకరణ',
    },
    'hi': {
      'title':           'खाता बनाएं',
      'subtitle':        'उझवन — किसान / मशीन मालिक',
      'who':             'आप कौन हैं?',
      'who_sub':         'उझवन प्लेटफॉर्म पर अपनी भूमिका चुनें',
      'farmer':          'किसान',
      'farmer_sub':      'मशीनें किराए पर लें',
      'owner':           'मशीन मालिक',
      'owner_sub':       'मशीनें किराए पर दें',
      'details':         'आपकी जानकारी',
      'details_sub':     'टाइप करें या 🎤 से बोलें',
      'name':            'पूरा नाम',
      'name_hint':       'जैसे: रामलाल शर्मा',
      'phone':           'मोबाइल नंबर',
      'phone_hint':      '9876543210',
      'village':         'गाँव / शहर',
      'village_hint':    'जैसे: भोपाल',
      'district':        'जिला',
      'district_hint':   'जैसे: भोपाल',
      'password':        'पासवर्ड (वैकल्पिक)',
      'password_hint':   '6+ अक्षर',
      'verify':          'OTP सत्यापित करें',
      'verify_sub':      'आपके नंबर पर OTP भेजा गया',
      'otp_label':       'OTP कोड',
      'otp_hint':        '• • • • • •',
      'change':          'नंबर बदलें',
      'next':            'आगे →',
      'submit':          'पंजीकरण ✓',
      'login':           'पहले से खाता है? लॉग इन',
      'err_name':        'पूरा नाम दर्ज करें',
      'err_phone':       '10 अंकों का नंबर दर्ज करें',
      'err_village':     'गाँव दर्ज करें',
      'err_district':    'जिला दर्ज करें',
      'err_otp':         '6 अंकों का OTP दर्ज करें',
      'step_lang':       'भाषा & भूमिका',
      'step_details':    'जानकारी',
      'step_verify':     'सत्यापन',
    },
    'en': {
      'title':           'Create Account',
      'subtitle':        'Uzhavan — Farmer / Machine Owner',
      'who':             'Who are you?',
      'who_sub':         'Select your role on the Uzhavan platform',
      'farmer':          'Farmer',
      'farmer_sub':      'Rent farming machines',
      'owner':           'Machine Owner',
      'owner_sub':       'List your machines for rent',
      'details':         'Your Details',
      'details_sub':     'Type or speak 🎤 any field',
      'name':            'Full Name',
      'name_hint':       'e.g. Murugan Selvam',
      'phone':           'Mobile Number',
      'phone_hint':      '9876543210',
      'village':         'Village / Town',
      'village_hint':    'e.g. Thanjavur',
      'district':        'District',
      'district_hint':   'e.g. Thanjavur',
      'password':        'Password (optional)',
      'password_hint':   '6+ characters',
      'verify':          'Verify OTP',
      'verify_sub':      'OTP sent to your number',
      'otp_label':       'OTP Code',
      'otp_hint':        '• • • • • •',
      'change':          'Change number',
      'next':            'Next →',
      'submit':          'Register ✓',
      'login':           'Already have an account? Login',
      'err_name':        'Please enter your full name',
      'err_phone':       'Enter a valid 10-digit number',
      'err_village':     'Please enter your village/town',
      'err_district':    'Please enter your district',
      'err_otp':         'Please enter the 6-digit OTP',
      'step_lang':       'Language & Role',
      'step_details':    'Details',
      'step_verify':     'Verify',
    },
  };

  String _t(String key) => _s[_lang]?[key] ?? _s['en']?[key] ?? key;

  String get _voiceLocale {
    return const {
      'ta': 'ta-IN',
      'te': 'te-IN',
      'hi': 'hi-IN',
      'en': 'en-IN',
    }[_lang] ?? 'ta-IN';
  }


  static const _langs = [
    {'code': 'ta', 'label': 'த',  'name': 'தமிழ்'},
    {'code': 'te', 'label': 'తె', 'name': 'తెలుగు'},
    {'code': 'hi', 'label': 'हि', 'name': 'हिंदी'},
    {'code': 'en', 'label': 'En', 'name': 'English'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _otpCtrl, _passwordCtrl, _villageCtrl, _districtCtrl, _machineModelCtrl, _machinePriceCtrl]) {
      c.dispose();
    }
    _animCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0) {
      // Auto-fetch GPS when entering details step
      _fetchGps();
    }
    if (_step == 1) {
      if (_nameCtrl.text.trim().isEmpty)          { setState(() => _error = _t('err_name'));     return; }
      if (_phoneCtrl.text.trim().length < 10)      { setState(() => _error = _t('err_phone'));    return; }
      if (_villageCtrl.text.trim().isEmpty)        { setState(() => _error = _t('err_village'));  return; }
      if (_districtCtrl.text.trim().isEmpty)       { setState(() => _error = _t('err_district')); return; }
    }
    setState(() { _error = null; _step++; });
    _animCtrl..reset()..forward();
    if (_step == 2) _sendOtp();
  }

  Future<void> _fetchGps() async {
    if (_gpsLoading) return;
    setState(() { _gpsLoading = true; _gpsStatus = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _gpsStatus = 'GPS சேவை இயக்கவில்லை'; _gpsLoading = false; });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() { _gpsStatus = 'இருப்பிட அனுமதி மறுக்கப்பட்டது'; _gpsLoading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _regLat = pos.latitude;
      _regLng = pos.longitude;
      // Reverse geocode using free Nominatim API
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json&addressdetails=1',
      );
      final resp = await http.get(url, headers: {'User-Agent': 'UzhavanApp/1.0'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final village = (addr['village'] ?? addr['town'] ?? addr['city'] ?? addr['county'] ?? '').toString();
        final district = (addr['state_district'] ?? addr['county'] ?? addr['state'] ?? '').toString();
        if (village.isNotEmpty && _villageCtrl.text.trim().isEmpty) _villageCtrl.text = village;
        if (district.isNotEmpty && _districtCtrl.text.trim().isEmpty) _districtCtrl.text = district;
        setState(() { _gpsStatus = '✅ இருப்பிடம் கண்டறியப்பட்டது'; });
      } else {
        setState(() { _gpsStatus = '✅ GPS கிடைத்தது (ஊர் கண்டறிய முடியவில்லை)'; });
      }
      context.read<AppState>().setLocation(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() { _gpsStatus = 'GPS பிழை: இயக்க சாதனத்தை அனுமதிக்கவும்'; });
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _error = null; });
    final appState = context.read<AppState>();
    try {
      final otp = await appState.sendOtp(_phoneCtrl.text.trim());
      setState(() => _devOtp = otp);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_otpCtrl.text.trim().length < 6) {
      setState(() => _error = _t('err_otp'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    final appState = context.read<AppState>();
    try {
      await appState.register(
        phone: _phoneCtrl.text.trim(),
        otp: _otpCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        role: _role.name,
        preferredLanguage: _lang,
        password: _passwordCtrl.text.trim().isNotEmpty ? _passwordCtrl.text.trim() : null,
        village: _villageCtrl.text.trim().isNotEmpty ? _villageCtrl.text.trim() : null,
        district: _districtCtrl.text.trim().isNotEmpty ? _districtCtrl.text.trim() : null,
        latitude: _regLat,
        longitude: _regLng,
      );

      // Store machine in backend for BOTH farmer and machine owner if provided
      if (_machineModelCtrl.text.trim().isNotEmpty) {
        final price = double.tryParse(_machinePriceCtrl.text.trim()) ?? 800.0;
        await appState.machineRepo.create(
          type: _machineType,
          model: _machineModelCtrl.text.trim(),
          pricePerHour: price,
          operatorIncluded: _operatorIncluded,
          latitude: appState.latitude,
          longitude: appState.longitude,
        );
      }

      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFFF0F4F0)],
                stops: [0.0, 0.35, 0.70],
              ),
            ),
          ),
          Positioned(top: -60, right: -60, child: _Circle(180, 0.08)),
          Positioned(top: 100, left: -40, child: _Circle(110, 0.05)),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStepDots(),
                const SizedBox(height: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        children: [
                          // Card
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 28, offset: const Offset(0, 8),
                              )],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildStepContent(),
                            ),
                          ),

                          // Error
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 18),
                          _buildActions(),
                          const SizedBox(height: 14),

                          if (_step == 0)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Center(child: Text(_t('login'),
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        if (_step > 0)
          GestureDetector(
            onTap: () { setState(() { _step--; _error = null; }); _animCtrl..reset()..forward(); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          )
        else
          const SizedBox(width: 40),
        Expanded(child: Column(children: [
          Text(_t('title'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text('Uzhavan — உழவன்', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        ])),
        const SizedBox(width: 40),
      ]),
    );
  }

  Widget _buildStepDots() {
    final steps = [_t('step_lang'), _t('step_details'), _t('step_verify')];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(children: List.generate(steps.length, (i) {
        final done   = i < _step;
        final active = i == _step;
        return Expanded(child: Row(children: [
          Expanded(child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 36 : 28, height: active ? 36 : 28,
              decoration: BoxDecoration(
                color: done || active ? Colors.white : Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)] : [],
              ),
              child: Center(child: done
                  ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 16)
                  : Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: active ? 15 : 13, color: active ? AppColors.primary : Colors.white70))),
            ),
            const SizedBox(height: 4),
            Text(steps[i], style: TextStyle(fontSize: 10, color: active ? Colors.white : Colors.white60, fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
          ])),
          if (i < steps.length - 1)
            Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18),
                color: i < _step ? Colors.white : Colors.white.withValues(alpha: 0.30))),
        ]));
      })),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _StepLangRole(
        key: const ValueKey(0),
        lang: _lang, role: _role, langs: _langs,
        t: _t,
        onLang: (l) => setState(() { _lang = l; _error = null; }),
        onRole: (r) => setState(() => _role = r),
      );
      case 1: return _StepPersonal(
        key: const ValueKey(1),
        isOwner: _role == _UserRole.owner,
        nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl,
        villageCtrl: _villageCtrl, districtCtrl: _districtCtrl,
        passwordCtrl: _passwordCtrl,
        machineModelCtrl: _machineModelCtrl,
        machinePriceCtrl: _machinePriceCtrl,
        machineType: _machineType,
        operatorIncluded: _operatorIncluded,
        onMachineTypeChanged: (t) => setState(() => _machineType = t),
        onOperatorChanged: (v) => setState(() => _operatorIncluded = v),
        obscure: _obscure, onObscure: () => setState(() => _obscure = !_obscure),
        t: _t,
        voiceLocale: _voiceLocale,
        gpsLoading: _gpsLoading,
        gpsStatus: _gpsStatus,
        onFetchGps: _fetchGps,
      );
      case 2: return _StepOtp(
        key: const ValueKey(2),
        otpCtrl: _otpCtrl, phone: _phoneCtrl.text.trim(),
        devOtp: _devOtp,
        t: _t,
        onChange: () => setState(() { _step--; _otpCtrl.clear(); _devOtp = null; }),
      );
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildActions() {
    final isLast = _step == 2;
    return ElevatedButton(
      onPressed: _loading ? null : (isLast ? _register : _nextStep),
      style: ElevatedButton.styleFrom(
        backgroundColor: _role == _UserRole.owner ? AppColors.ownerAccent : AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: _loading ? 0 : 6,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
      ),
      child: _loading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 22),
              const SizedBox(width: 10),
              Text(isLast ? _t('submit') : _t('next'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0: Language + Role
// ─────────────────────────────────────────────────────────────────────────────
class _StepLangRole extends StatelessWidget {
  const _StepLangRole({
    super.key,
    required this.lang, required this.role,
    required this.langs, required this.t,
    required this.onLang, required this.onRole,
  });
  final String lang;
  final _UserRole role;
  final List<Map<String, String>> langs;
  final String Function(String) t;
  final ValueChanged<String> onLang;
  final ValueChanged<_UserRole> onRole;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Language row
      Row(mainAxisAlignment: MainAxisAlignment.center,
        children: langs.map((l) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: () => onLang(l['code']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50, height: 38,
              decoration: BoxDecoration(
                color: lang == l['code'] ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: lang == l['code'] ? AppColors.primary : AppColors.divider, width: 1.5),
              ),
              child: Center(child: Text(l['label']!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                      color: lang == l['code'] ? Colors.white : AppColors.textSecondary))),
            ),
          ),
        )).toList(),
      ),
      const SizedBox(height: 24),

      Text(t('who'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(t('who_sub'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 20),

      _RoleCard(
        icon: Icons.person_rounded, color: AppColors.primary,
        label: t('farmer'), sublabel: t('farmer_sub'),
        selected: role == _UserRole.farmer,
        onTap: () => onRole(_UserRole.farmer),
      ),
      const SizedBox(height: 12),
      _RoleCard(
        icon: Icons.agriculture_rounded, color: AppColors.ownerAccent,
        label: t('owner'), sublabel: t('owner_sub'),
        selected: role == _UserRole.owner,
        onTap: () => onRole(_UserRole.owner),
      ),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.color, required this.label,
      required this.sublabel, required this.selected, required this.onTap});
  final IconData icon; final Color color; final String label, sublabel;
  final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10)] : [],
      ),
      child: Row(children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: selected ? color : AppColors.textPrimary)),
          Text(sublabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ])),
        if (selected) Icon(Icons.check_circle_rounded, color: color, size: 24),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Personal Details
// ─────────────────────────────────────────────────────────────────────────────
class _StepPersonal extends StatelessWidget {
  const _StepPersonal({
    super.key,
    required this.isOwner,
    required this.nameCtrl, required this.phoneCtrl,
    required this.villageCtrl, required this.districtCtrl,
    required this.passwordCtrl,
    required this.machineModelCtrl,
    required this.machinePriceCtrl,
    required this.machineType,
    required this.operatorIncluded,
    required this.onMachineTypeChanged,
    required this.onOperatorChanged,
    required this.obscure, required this.onObscure,
    required this.t,
    required this.voiceLocale,
    required this.gpsLoading,
    required this.onFetchGps,
    this.gpsStatus,
  });
  final bool isOwner;
  final TextEditingController nameCtrl, phoneCtrl, villageCtrl, districtCtrl, passwordCtrl;
  final TextEditingController machineModelCtrl, machinePriceCtrl;
  final String machineType;
  final bool operatorIncluded;
  final ValueChanged<String> onMachineTypeChanged;
  final ValueChanged<bool> onOperatorChanged;
  final bool obscure;
  final VoidCallback onObscure;
  final String Function(String) t;
  final String voiceLocale;
  final bool gpsLoading;
  final VoidCallback onFetchGps;
  final String? gpsStatus;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t('details'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(t('details_sub'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 14),

      // ── GPS Location Banner ──────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            gpsLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                gpsStatus ?? 'இருப்பிடம் தானாக கண்டறிய அனுமதி தேவை / Allow location to auto-fill village',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: gpsLoading ? null : onFetchGps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  gpsLoading ? 'கண்டறிகிறது...' : '📍 இருப்பிடம்',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      VoiceTextField(
        controller: nameCtrl,
        label: t('name'),
        hint: t('name_hint'),
        icon: Icons.person_rounded,
        languageCode: voiceLocale,
      ),
      const SizedBox(height: 16),

      _FL(t('phone')),
      const SizedBox(height: 6),
      TextFormField(
        controller: phoneCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 2),
        decoration: _deco(hint: t('phone_hint'), prefix: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE0E0E0)))),
          child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 16)),
        )),
      ),
      const SizedBox(height: 16),

      VoiceTextField(
        controller: villageCtrl,
        label: t('village'),
        hint: t('village_hint'),
        icon: Icons.location_city_rounded,
        languageCode: voiceLocale,
      ),
      const SizedBox(height: 16),

      VoiceTextField(
        controller: districtCtrl,
        label: t('district'),
        hint: t('district_hint'),
        icon: Icons.map_rounded,
        languageCode: voiceLocale,
      ),
      const SizedBox(height: 16),

      _FL(t('password')),
      const SizedBox(height: 6),
      TextFormField(
        controller: passwordCtrl,
        obscureText: obscure,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: _deco(hint: t('password_hint'), icon: Icons.lock_rounded).copyWith(
          suffixIcon: IconButton(
            onPressed: onObscure,
            icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textSecondary, size: 22),
          ),
        ),
      ),

      // Machine Details Section shown ONLY for Machine Owner role
      if (isOwner) ...[
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ownerAccent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ownerAccent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.agriculture_rounded, color: AppColors.ownerAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'எந்திரம் சேர்க்க (விருப்பம்) / Add Machine',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ownerAccent),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            const Text(
              'உங்களிடம் உள்ள எந்திர விபரங்களை பதிவு செய்யுங்கள்',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            _FL('எந்திர வகை / Machine Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: machineType.isEmpty ? 'tractor' : machineType,
              decoration: _deco(hint: 'எந்திர வகை', icon: Icons.agriculture_rounded),
              items: const [
                DropdownMenuItem(value: 'tractor', child: Text('டிராக்டர் / Tractor', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'harvester', child: Text('அறுவடை எந்திரம் / Harvester', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'plough', child: Text('உழவு எந்திரம் / Rotary Plough', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'seeder', child: Text('விதைப்பான் / Seeder', overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(value: 'sprayer', child: Text('தெளிப்பான் / Sprayer', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) { if (v != null) onMachineTypeChanged(v); },
            ),
            const SizedBox(height: 12),

            VoiceTextField(
              controller: machineModelCtrl,
              label: 'எந்திரத்தின் பெயர் & மாடல் / Model Name',
              hint: 'எ.கா. Mahindra 575 DI / Sonalika',
              icon: Icons.label_important_outline_rounded,
              languageCode: voiceLocale,
            ),
            const SizedBox(height: 12),

            _FL('மணிநேர வாடகை கட்டணம் (₹) / Price per Hour'),
            const SizedBox(height: 6),
            TextFormField(
              controller: machinePriceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              decoration: _deco(hint: '850', icon: Icons.payments_rounded),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('இயக்குனர் உண்டு / Operator Included', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              value: operatorIncluded,
              onChanged: onOperatorChanged,
            ),
          ],
        ),
      ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: OTP Verify
// ─────────────────────────────────────────────────────────────────────────────
class _StepOtp extends StatelessWidget {
  const _StepOtp({
    super.key,
    required this.otpCtrl, required this.phone,
    required this.devOtp, required this.t,
    required this.onChange,
  });
  final TextEditingController otpCtrl;
  final String phone;
  final String? devOtp;
  final String Function(String) t;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t('verify'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text('${t('verify_sub')}: +91 $phone', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 24),

      _FL(t('otp_label')),
      const SizedBox(height: 8),
      TextFormField(
        controller: otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12, color: AppColors.primary),
        decoration: _deco(hint: t('otp_hint'), helperText: devOtp != null ? '🔑 Dev OTP: $devOtp' : null),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
          label: Text(t('change'), style: const TextStyle(color: AppColors.primary, fontSize: 13)),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration _deco({required String hint, Widget? prefix, IconData? icon, String? helperText}) {
  return InputDecoration(
    hintText: hint, counterText: '',
    helperText: helperText,
    helperStyle: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
    prefixIcon: prefix ?? (icon != null ? Icon(icon, color: AppColors.primary, size: 22) : null),
    filled: true, fillColor: const Color(0xFFF8F8F8),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}

class _FL extends StatelessWidget {
  const _FL(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.3));
}


class _Circle extends StatelessWidget {
  const _Circle(this.size, this.opacity);
  final double size, opacity;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
  );
}
