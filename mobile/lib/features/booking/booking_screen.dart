import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/machine_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/voice_confirmation_dialog.dart';
import '../../core/widgets/large_action_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.machine});

  final MachineModel machine;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  DateTime _selectedDate = DateTime.now();
  int _durationHours = 4;
  String _paymentMethod = 'UPI'; // 'UPI' or 'CASH'
  bool _loading = false;
  bool _isSuccess = false;
  String? _bookingSummary;

  void _speakValue(String valueText) {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    TTSService.speak(valueText, lang: lang);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _speakValue('${picked.day} தேதி தேர்ந்தெடுக்கப்பட்டது');
    }
  }

  Future<void> _submitBooking() async {
    final confirmed = await VoiceConfirmationDialog.show(
      context,
      title: 'முன்பதிவு உறுதி செய்தல் / Confirm Booking',
      message: '${widget.machine.model ?? widget.machine.type}, ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}, $_durationHours மணிநேரம், செலுத்தும் முறை: $_paymentMethod. உறுதி செய்யவா?',
      actionLabel: 'முன்பதிவு செய் / BOOK NOW',
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final appState = context.read<AppState>();
      final booking = await appState.bookingRepo.create(
        machineId: widget.machine.id,
        startDate: _selectedDate,
        endDate: _selectedDate.add(Duration(hours: _durationHours)),
        farmerLat: appState.latitude,
        farmerLng: appState.longitude,
        farmerVillage: appState.village,
        hours: _durationHours.toDouble(),
        operatorIncluded: widget.machine.operatorIncluded,
      );

      final lang = appState.user?.preferredLanguage ?? 'ta';
      final summary = 'வாழ்த்துக்கள்! உங்கள் முன்பதிவு வெற்றி. எந்திரம்: ${widget.machine.model ?? widget.machine.type}, நாள்: ${_selectedDate.day}/${_selectedDate.month}, நேரம்: $_durationHours மணிநேரம்.';

      setState(() {
        _loading = false;
        _isSuccess = true;
        _bookingSummary = summary;
      });

      TTSService.speak(summary, lang: lang);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('பிழை: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('முன்பதிவு / Book Machine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              color: Colors.white,
              child: Row(
                children: List.generate(3, (index) {
                  final active = index <= _step;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepView(),
              ),
            ),

            // Stepper Navigation Footer
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('பின்னே / BACK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                if (_step < 2) {
                                  setState(() => _step++);
                                } else {
                                  _submitBooking();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _step == 2 ? 'உறுதி செய் / CONFIRM' : 'அடுத்து / NEXT',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepView() {
    switch (_step) {
      case 0:
        return _buildStep1DateSelection();
      case 1:
        return _buildStep2DurationStepper();
      case 2:
        return _buildStep3PaymentMethod();
      default:
        return Container();
    }
  }

  // Step 1: Date Picker (Today highlighted)
  Widget _buildStep1DateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 1: தேதி தேர்வு / Step 1: Pick Date', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 36, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('முன்பதிவு நாள் / Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _pickDate,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('மாற்று / CHANGE', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Set duration / area via +/- stepper (spoken back on change)
  Widget _buildStep2DurationStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 2: நேரம் / அளவு அமைத்தல் / Step 2: Duration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text('$_durationHours மணிநேரம்', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 28),
                onPressed: () => _speakValue('$_durationHours மணிநேரம்'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 72,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_durationHours > 1) {
                    setState(() => _durationHours--);
                    _speakValue('$_durationHours மணிநேரம்');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('-', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 72,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _durationHours++);
                  _speakValue('$_durationHours மணிநேரம்');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('+', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Choose Payment Method (UPI or Cash on Pickup)
  Widget _buildStep3PaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 3: பணம் செலுத்தும் முறை / Step 3: Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        // UPI Option
        GestureDetector(
          onTap: () {
            setState(() => _paymentMethod = 'UPI');
            _speakValue('யு.பி.ஐ மூலம் செலுத்தப்படும்');
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _paymentMethod == 'UPI' ? AppColors.primary : Colors.grey.shade300, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, size: 32, color: _paymentMethod == 'UPI' ? AppColors.primary : Colors.grey),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPI (Google Pay / PhonePe)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('ஆன்லைன் கட்டணம் / Online Payment', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (_paymentMethod == 'UPI') const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
              ],
            ),
          ),
        ),

        // Cash on Pickup Option
        GestureDetector(
          onTap: () {
            setState(() => _paymentMethod = 'CASH');
            _speakValue('நேரில் ரொக்கமாக செலுத்தப்படும்');
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _paymentMethod == 'CASH' ? AppColors.primary : Colors.grey.shade300, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_rounded, size: 32, color: _paymentMethod == 'CASH' ? AppColors.primary : Colors.grey),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash on Pickup / ரொக்கம்', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('எந்திரம் பெறும்போது ரொக்கம் செலுத்தலாம்', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (_paymentMethod == 'CASH') const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Full Screen Success Animation + Summary Text + TTS Readback
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 24),
              const Text('முன்பதிவு வெற்றி! / Booking Success', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  _bookingSummary ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('முடிந்தது / DONE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
