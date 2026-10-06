/// Uzhavan — Voice-Driven Smart Booking Sheet
///
/// 3-step modal flow:
///   Step 1 — Summary (matched machine + price estimate)
///   Step 2 — Verify Your Details (editable farmer info + TTS per-field)
///   Step 3 — Success (TTS confirmation, booking sent to owner)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/models/machine_model.dart';
import '../../core/models/voice_booking_request.dart';
import '../../core/providers/app_state.dart';
import '../../core/repositories/machine_repository.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/voice_booking_parser.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/speech_manager.dart';

class VoiceBookingSheet extends StatefulWidget {
  const VoiceBookingSheet({
    super.key,
    required this.request,
  });

  final VoiceBookingRequest request;

  /// Show the sheet as a full-screen modal
  static Future<void> show(BuildContext context, VoiceBookingRequest request) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      builder: (_) => VoiceBookingSheet(request: request),
    );
  }

  @override
  State<VoiceBookingSheet> createState() => _VoiceBookingSheetState();
}

class _VoiceBookingSheetState extends State<VoiceBookingSheet> {
  int _step = 0; // 0=Summary, 1=Verify, 2=Success
  bool _searching = true;
  bool _booking = false;
  MachineModel? _machine;
  String? _searchError;

  late VoiceBookingRequest _request;

  // Verify step editable fields
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _villageCtrl;

  // Voice confirmation on verify step
  final stt.SpeechToText _speech = SpeechManager.instance;
  bool _listeningForConfirm = false;
  String _listenStatus = '';

  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _initControllers();
    _searchMachine();
  }

  void _initControllers() {
    final appState = context.read<AppState>();
    final user = appState.user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _villageCtrl = TextEditingController(
      text: [user?.village, user?.district].where((v) => v != null && v.isNotEmpty).join(', '),
    );
  }

  Future<void> _searchMachine() async {
    final appState = context.read<AppState>();
    setState(() { _searching = true; _searchError = null; });
    try {
      final results = await appState.machineRepo.search(
        latitude: appState.latitude,
        longitude: appState.longitude,
        type: _request.machineTypeString,
        startDate: _request.preferredDate,
        endDate: _request.preferredDate.add(const Duration(days: 1)),
      );
      if (!mounted) return;
      setState(() {
        _machine = results.isNotEmpty ? results.first : null;
        _searching = false;
        _searchError = results.isEmpty ? 'No machine found nearby. Try a different date.' : null;
      });
      // Speak summary after machine is found
      if (_machine != null) {
        await Future.delayed(const Duration(milliseconds: 600));
        _speakStep1Summary();
      }
    } catch (e) {
      if (mounted) setState(() { _searching = false; _searchError = e.toString(); });
    }
  }

  void _speakStep1Summary() {
    if (_machine == null) return;
    final lang = _request.lang;
    final price = _estimatedPrice();
    final priceStr = price != null ? '₹${price.toStringAsFixed(0)}' : '';

    String msg;
    if (lang == 'ta') {
      msg = '${_machine!.model ?? _machine!.type} கிடைத்தது. '
          '${_machine!.distanceKm?.toStringAsFixed(1) ?? ""} கிலோமீட்டர் தூரத்தில் உள்ளது. '
          '${_request.areaAcres.toStringAsFixed(0)} ஏக்கருக்கு மதிப்பீடு $priceStr. '
          'அடுத்து செல்ல அடுத்து என்று சொல்லுங்கள்.';
    } else if (lang == 'te') {
      msg = '${_machine!.model ?? _machine!.type} దొరికింది. ${_machine!.distanceKm?.toStringAsFixed(1) ?? ""} కి.మీ దూరంలో ఉంది. అంచనా $priceStr.';
    } else if (lang == 'hi') {
      msg = '${_machine!.model ?? _machine!.type} मिली। ${_machine!.distanceKm?.toStringAsFixed(1) ?? ""} किमी दूर है। अनुमानित कीमत $priceStr।';
    } else {
      msg = 'Found ${_machine!.model ?? _machine!.type} ${_machine!.distanceKm?.toStringAsFixed(1) ?? ""} km away. Estimated price $priceStr for ${_request.areaAcres.toStringAsFixed(0)} acres.';
    }
    _speak(msg);
  }

  void _speakStep2Summary() {
    final lang = _request.lang;
    final name = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : '—';
    final phone = _phoneCtrl.text.isNotEmpty ? _phoneCtrl.text : '—';
    final village = _villageCtrl.text.isNotEmpty ? _villageCtrl.text : '—';
    final area = '${_request.areaAcres.toStringAsFixed(0)}';
    final date = _request.dateLabel;

    String msg;
    if (lang == 'ta') {
      msg = 'உங்கள் பெயர் $name. தொலைபேசி எண் $phone. கிராமம் $village. '
          '$area ஏக்கர் நிலம். $date தேதி. '
          'இந்த விவரங்கள் சரியா? சரி என்று சொல்லுங்கள்.';
    } else if (lang == 'te') {
      msg = 'మీ పేరు $name. ఫోన్ $phone. గ్రామం $village. $area ఎకరాలు. $date. వివరాలు సరైనవేనా?';
    } else if (lang == 'hi') {
      msg = 'आपका नाम $name। फोन $phone। गांव $village। $area एकड़। $date। क्या ये सही है? हां बोलें।';
    } else {
      msg = 'Your name is $name. Phone $phone. Village $village. $area acres. $date. Is this correct? Say yes to confirm.';
    }
    _speak(msg);
  }

  void _speak(String text) {
    final langCode = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[_request.lang] ?? 'ta-IN';
    _tts.setLanguage(langCode);
    _tts.speak(text);
  }

  void _speakField(String text) => _speak(text);

  double? _estimatedPrice() {
    final m = _machine;
    if (m == null) return null;
    if (m.pricePerAcre != null) return m.pricePerAcre! * _request.areaAcres;
    if (m.pricePerHour != null) return m.pricePerHour! * (_request.areaAcres * 2); // ~2h/acre
    return null;
  }

  Future<void> _startVoiceConfirm() async {
    setState(() { _listeningForConfirm = true; _listenStatus = 'கேட்கிறது... / Listening...'; });
    try {
      await _speech.initialize();
      final langCode = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[_request.lang] ?? 'ta-IN';
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: langCode,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords.toLowerCase().trim();
          final confirmed = _isYes(words);
          final rejected = _isNo(words);
          if ((result.finalResult || confirmed || rejected) && words.isNotEmpty) {
            _speech.stop();
            setState(() { _listeningForConfirm = false; _listenStatus = ''; });
            if (confirmed) _submitBooking();
            if (rejected) Navigator.pop(context);
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() { _listeningForConfirm = false; _listenStatus = ''; });
    }
  }

  bool _isYes(String t) => ['yes', 'சரி', 'ஆமாம்', 'confirm', 'ok', 'okay', 'అవును', 'हां', 'हाँ'].any(t.contains);
  bool _isNo(String t) => ['no', 'வேண்டாம்', 'இல்லை', 'cancel', 'వద్దు', 'नहीं'].any(t.contains);

  Future<void> _submitBooking() async {
    if (_machine == null) return;
    setState(() => _booking = true);

    try {
      final appState = context.read<AppState>();
      await appState.bookingRepo.create(
        machineId: _machine!.id,
        startDate: _request.preferredDate,
        endDate: _request.preferredDate.add(const Duration(days: 1)),
        areaAcres: _request.areaAcres,
        farmerLat: appState.latitude,
        farmerLng: appState.longitude,
        farmerVillage: _villageCtrl.text.isNotEmpty ? _villageCtrl.text : appState.village,
        operatorIncluded: _machine!.operatorIncluded,
      );
      if (!mounted) return;
      setState(() { _booking = false; _step = 2; });

      final ownerName = _machine!.owner?.name ?? 'உரிமையாளர்';
      final lang = _request.lang;
      String successMsg;
      if (lang == 'ta') {
        successMsg = 'முன்பதிவு வெற்றி! $ownerName உங்கள் கோரிக்கையை பெற்றுள்ளார். '
            'விரைவில் உங்களை தொடர்பு கொள்வார்.';
      } else if (lang == 'te') {
        successMsg = 'బుకింగ్ విజయవంతమైంది! $ownerName మీ అభ్యర్థనను అందుకున్నారు.';
      } else if (lang == 'hi') {
        successMsg = 'बुकिंग सफल! $ownerName को आपकी बुकिंग मिल गई है।';
      } else {
        successMsg = 'Booking successful! $ownerName has received your request and will contact you soon.';
      }
      _speak(successMsg);
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('பிழை / Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildStepIndicator(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 5,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success
                    : active
                        ? AppColors.primary
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0: return _buildSummaryStep();
      case 1: return _buildVerifyStep();
      case 2: return _buildSuccessStep();
      default: return const SizedBox();
    }
  }

  // ── STEP 1: Summary ─────────────────────────────────────────────────────────

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('குரல் முன்பதிவு', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                Text('Voice Smart Booking', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
          ]),

          const SizedBox(height: 20),

          // What was heard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.mic_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${widget.request.originalSpeech}"',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Request extracted summary
          _SectionCard(
            icon: Icons.agriculture_rounded,
            title: 'முன்பதிவு விவரம் / Request',
            child: Column(children: [
              _InfoRow('🚜', 'எந்திரம் / Machine', _request.machineLabel),
              _InfoRow('⚙️', 'பணி / Task', _request.taskLabel),
              _InfoRow('📐', 'நிலம் / Area', '${_request.areaAcres.toStringAsFixed(0)} Acres'),
              _InfoRow('📅', 'தேதி / Date', _request.dateLabel),
            ]),
          ),

          const SizedBox(height: 16),

          // Machine search result
          if (_searching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('அருகில் உள்ள எந்திரம் தேடுகிறோம்...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              ),
            )
          else if (_searchError != null)
            _ErrorCard(message: _searchError!, onRetry: _searchMachine)
          else if (_machine != null)
            _MachineCard(machine: _machine!, estimatedPrice: _estimatedPrice()),

          const SizedBox(height: 20),

          if (!_searching && _machine != null) ...[
            // TTS button
            _TtsButton(onTap: _speakStep1Summary, lang: _request.lang),
            const SizedBox(height: 16),
            // Next
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: const Text('அடுத்து / NEXT →', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => setState(() => _step = 1),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── STEP 2: Verify Your Details ──────────────────────────────────────────────

  Widget _buildVerifyStep() {
    final price = _estimatedPrice();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.fact_check_rounded, color: AppColors.success, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('உங்கள் விவரங்களை சரிபார்க்கவும்', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                Text('Verify Your Details', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
          ]),

          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.info_rounded, size: 16, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'முன்பதிவு அனுப்புவதற்கு முன்பு கீழுள்ள விவரங்களை சரிபாருங்கள்.\nPlease verify all details before sending the booking request.',
                  style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Name
          _VerifyField(
            icon: Icons.person_rounded,
            label: 'பெயர் / Name',
            controller: _nameCtrl,
            onSpeak: () => _speakField('உங்கள் பெயர் ${_nameCtrl.text}'),
          ),
          const SizedBox(height: 12),

          // Phone
          _VerifyField(
            icon: Icons.phone_rounded,
            label: 'தொலைபேசி / Phone',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            onSpeak: () => _speakField('தொலைபேசி எண் ${_phoneCtrl.text}'),
          ),
          const SizedBox(height: 12),

          // Village
          _VerifyField(
            icon: Icons.location_on_rounded,
            label: 'கிராமம் / Village & District',
            controller: _villageCtrl,
            onSpeak: () => _speakField('கிராமம் ${_villageCtrl.text}'),
          ),
          const SizedBox(height: 12),

          // Area stepper
          _AreaStepper(
            acres: _request.areaAcres,
            lang: _request.lang,
            onChanged: (v) {
              setState(() => _request = _request.copyWith(areaAcres: v));
              _speakField('${v.toStringAsFixed(0)} ஏக்கர்');
            },
          ),
          const SizedBox(height: 12),

          // Date
          _DateRow(
            date: _request.preferredDate,
            lang: _request.lang,
            onSpeak: () => _speakField('தேதி ${_request.dateLabel}'),
            onChanged: (d) => setState(() => _request = _request.copyWith(preferredDate: d)),
          ),

          const SizedBox(height: 20),

          // Price estimate
          if (price != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('மதிப்பீட்டு விலை / Estimated Price', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ]),
              ]),
            ),

          const SizedBox(height: 16),

          // TTS full summary read
          _TtsButton(
            onTap: _speakStep2Summary,
            label: 'அனைத்து விவரங்களையும் கேளுங்கள் / Hear all details',
            lang: _request.lang,
          ),

          const SizedBox(height: 16),

          // Voice confirm status
          if (_listeningForConfirm)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.mic_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_listenStatus, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13))),
                GestureDetector(
                  onTap: () { _speech.stop(); setState(() { _listeningForConfirm = false; _listenStatus = ''; }); },
                  child: const Icon(Icons.stop_circle_rounded, color: AppColors.error),
                ),
              ]),
            ),

          const SizedBox(height: 16),

          // Confirm buttons
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('திரும்பு / BACK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _step = 0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: _booking
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _booking ? 'அனுப்புகிறோம்...' : 'உறுதி செய் / CONFIRM',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _booking ? null : _submitBooking,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 8),

          // Voice confirm tap
          Center(
            child: TextButton.icon(
              icon: Icon(
                _listeningForConfirm ? Icons.stop_circle_rounded : Icons.mic_rounded,
                color: _listeningForConfirm ? AppColors.error : AppColors.primary,
              ),
              label: Text(
                _listeningForConfirm
                    ? '"சரி" அல்லது "வேண்டாம்" சொல்லுங்கள்'
                    : 'குரலில் உறுதி செய் / Confirm by voice',
                style: TextStyle(
                  color: _listeningForConfirm ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              onPressed: _listeningForConfirm
                  ? () { _speech.stop(); setState(() { _listeningForConfirm = false; _listenStatus = ''; }); }
                  : () { _speakStep2Summary(); Future.delayed(const Duration(milliseconds: 2500), _startVoiceConfirm); },
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 3: Success ──────────────────────────────────────────────────────────

  Widget _buildSuccessStep() {
    final ownerName = _machine?.owner?.name ?? 'உரிமையாளர்';
    final ownerPhone = _machine?.owner?.phone ?? '';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 110, height: 110,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'முன்பதிவு வெற்றி!\nBooking Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(children: [
                _InfoRow('🚜', 'எந்திரம்', _machine?.model ?? _machine?.type ?? '—'),
                const SizedBox(height: 8),
                _InfoRow('📐', 'நிலம் / Area', '${_request.areaAcres.toStringAsFixed(0)} Acres'),
                const SizedBox(height: 8),
                _InfoRow('📅', 'தேதி / Date', _request.dateLabel),
                const SizedBox(height: 8),
                _InfoRow('👤', 'உரிமையாளர்', ownerName),
                if (ownerPhone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow('📞', 'தொலைபேசி', ownerPhone),
                ],
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'உரிமையாளர் உங்கள் கோரிக்கையை பெற்றுள்ளார்.\nOwner has received your booking request.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('முகப்புக்கு / HOME', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ]),
        const Divider(height: 16),
        child,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.emoji, this.label, this.value);
  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
      Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), textAlign: TextAlign.end)),
    ]);
  }
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({required this.machine, this.estimatedPrice});
  final MachineModel machine;
  final double? estimatedPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(machine.model ?? machine.type, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (machine.owner?.name != null)
                Text(machine.owner!.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (machine.distanceKm != null) ...[
            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text('${machine.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
          ],
          if (estimatedPrice != null) ...[
            const Icon(Icons.currency_rupee_rounded, size: 14, color: AppColors.primary),
            Text('${estimatedPrice!.toStringAsFixed(0)} est.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
              SizedBox(width: 4),
              Text('Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _TtsButton extends StatelessWidget {
  const _TtsButton({required this.onTap, this.label, required this.lang});
  final VoidCallback onTap;
  final String? label;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.volume_up_rounded, color: AppColors.info, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label ?? 'தமிழில் கேளுங்கள் / Hear in Tamil',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info),
            ),
          ),
          const Icon(Icons.play_circle_filled_rounded, color: AppColors.info, size: 20),
        ]),
      ),
    );
  }
}

class _VerifyField extends StatelessWidget {
  const _VerifyField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.onSpeak,
  });
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.info),
          onPressed: onSpeak,
          tooltip: 'Hear this field',
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

class _AreaStepper extends StatelessWidget {
  const _AreaStepper({required this.acres, required this.lang, required this.onChanged});
  final double acres;
  final String lang;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.straighten_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('நிலப்பரப்பு / Area', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          Text('${acres.toStringAsFixed(0)} ஏக்கர் / Acres', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const Spacer(),
        Row(children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: acres > 0.5 ? () => onChanged(acres - 0.5) : null),
          const SizedBox(width: 8),
          _StepBtn(icon: Icons.add_rounded, onTap: () => onChanged(acres + 0.5), color: AppColors.primary),
        ]),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? (color ?? Colors.grey.shade200) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: onTap != null ? (color != null ? Colors.white : AppColors.textPrimary) : AppColors.divider),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.lang, required this.onSpeak, required this.onChanged});
  final DateTime date;
  final String lang;
  final VoidCallback onSpeak;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = '${date.day}/${date.month}/${date.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('தேதி / Booking Date', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ]),
        ),
        IconButton(icon: const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.info), onPressed: onSpeak, padding: const EdgeInsets.all(6), constraints: const BoxConstraints()),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) onChanged(picked);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('மாற்று', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_rounded, color: AppColors.error),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600))),
        TextButton(onPressed: onRetry, child: const Text('Retry', style: TextStyle(color: AppColors.error))),
      ]),
    );
  }
}
