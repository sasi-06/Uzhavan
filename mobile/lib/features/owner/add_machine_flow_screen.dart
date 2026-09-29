import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../location/screens/location_picker_screen.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/machine_type_tile.dart';
import '../../core/widgets/large_action_button.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/voice_confirmation_dialog.dart';

class AddMachineFlowScreen extends StatefulWidget {
  const AddMachineFlowScreen({super.key});

  @override
  State<AddMachineFlowScreen> createState() => _AddMachineFlowScreenState();
}

class _AddMachineFlowScreenState extends State<AddMachineFlowScreen> {
  int _currentStep = 0;

  // Form State
  String _selectedType = 'tractor';
  bool _photoAdded = false;
  double _price = 800.0;
  String _priceUnit = 'per_hour'; // 'per_hour' or 'per_acre'
  final Set<DateTime> _blockedDates = {};
  String _voiceNoteText = '';
  bool _isRecordingVoiceNote = false;
  double _serviceRadiusKm = 15;
  Map<String, dynamic>? _locationData;

  void _nextStep() {
    if (_currentStep == 1 && !_photoAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('குறைந்தது 1 புகைப்படம் சேர்க்கப்பட வேண்டும் / At least 1 photo required')),
      );
      return;
    }
    if (_currentStep == 5 && _locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location / தயவுசெய்து இடத்தை தேர்ந்தெடுக்கவும்')),
      );
      return;
    }
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _submitMachine();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitMachine() async {
    final confirmed = await VoiceConfirmationDialog.show(
      context,
      title: 'எந்திரம் சேர்க்கை / Add Machine',
      message: 'வகைகள்: $_selectedType, விலை: ₹${_price.toInt()} / ${_priceUnit == 'per_hour' ? 'மணி' : 'ஏக்கர்'}. சேமிக்க வேண்டுமா?',
      actionLabel: 'சேமி / SAVE',
    );

    if (confirmed == true && mounted) {
      final appState = context.read<AppState>();
      try {
        await appState.machineRepo.create(
          type: _selectedType,
          model: 'New $_selectedType',
          pricePerHour: _priceUnit == 'per_hour' ? _price : null,
          pricePerAcre: _priceUnit == 'per_acre' ? _price : null,
          photos: ['https://images.unsplash.com/photo-1530267981375-f0de937f5f13?w=800'],
          latitude: _locationData?['lat'] ?? appState.latitude,
          longitude: _locationData?['lng'] ?? appState.longitude,
          village: _locationData?['village'],
          district: _locationData?['district'],
          serviceRadiusKm: _serviceRadiusKm,
        );

        if (mounted) {
          TTSService.speak('புதிய எந்திரம் வெற்றிகரமாக சேர்க்கப்பட்டது', lang: appState.user?.preferredLanguage ?? 'ta');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('பிழை: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().user?.preferredLanguage ?? 'ta';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.ownerAccent,
        title: const Text('புதிய எந்திரம் சேர்க்க / Add Machine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress Stepper Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              color: Colors.white,
              child: Row(
                children: List.generate(6, (index) {
                  final active = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ownerAccent : Colors.grey.shade300,
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
                child: _buildCurrentStepView(lang),
              ),
            ),

            // Bottom Navigation Stepper Controls
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.ownerAccent, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('பின்னே / BACK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ownerAccent)),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ownerAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _currentStep == 5 ? 'முடிக்க / SUBMIT' : 'அடுத்து / NEXT',
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

  Widget _buildCurrentStepView(String lang) {
    switch (_currentStep) {
      case 0:
        return _buildStep1MachineType();
      case 1:
        return _buildStep2CameraCapture();
      case 2:
        return _buildStep3PriceStepper();
      case 3:
        return _buildStep4AvailabilityCalendar();
      case 4:
        return _buildStep5VoiceNoteDescription(lang);
      case 5:
        return _buildStep6LocationAndRadius();
      default:
        return Container();
    }
  }

  // Step 6: Location and Service Radius
  Widget _buildStep6LocationAndRadius() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 6: இடம் மற்றும் சேவை வரம்பு / Step 6: Location & Radius', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: Text(_locationData == null ? 'Set Location' : 'Location Selected'),
            onPressed: () async {
              // Import LocationPickerScreen at the top
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LocationPickerScreen(isFarmer: false)),
              );
              if (result != null) {
                setState(() => _locationData = result as Map<String, dynamic>);
              }
            },
          ),
        ),
        const SizedBox(height: 32),
        const Text('Service Radius (km):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 32),
              onPressed: () {
                if (_serviceRadiusKm > 5) setState(() => _serviceRadiusKm -= 5);
              },
            ),
            Text('${_serviceRadiusKm.toInt()} km', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 32),
              onPressed: () {
                if (_serviceRadiusKm < 100) setState(() => _serviceRadiusKm += 5);
              },
            ),
          ],
        ),
      ],
    );
  }

  // Step 1: Pick Machine Type
  Widget _buildStep1MachineType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 1: எந்திர வகை தேர்வு / Step 1: Machine Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            MachineTypeTile(
              type: 'tractor',
              lang: 'ta',
              selected: _selectedType == 'tractor',
              onTap: () => setState(() => _selectedType = 'tractor'),
            ),
            MachineTypeTile(
              type: 'plough',
              lang: 'ta',
              selected: _selectedType == 'plough',
              onTap: () => setState(() => _selectedType = 'plough'),
            ),
            MachineTypeTile(
              type: 'harvester',
              lang: 'ta',
              selected: _selectedType == 'harvester',
              onTap: () => setState(() => _selectedType = 'harvester'),
            ),
            MachineTypeTile(
              type: 'seeder',
              lang: 'ta',
              selected: _selectedType == 'seeder',
              onTap: () => setState(() => _selectedType = 'seeder'),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Camera Capture with Framing Guide
  Widget _buildStep2CameraCapture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 2: எந்திர படம் எடுக்கவும் / Step 2: Machine Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('குறைந்தது 1 தெளிவான புகைப்படம் தேவை / Minimum 1 clear photo required', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            setState(() => _photoAdded = true);
            TTSService.speak('புகைப்படம் சேர்க்கப்பட்டது', lang: 'ta');
          },
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _photoAdded ? AppColors.success : AppColors.ownerAccent, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_photoAdded)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1530267981375-f0de937f5f13?w=800',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else ...[
                  // Framing Guide Box
                  Container(
                    width: 240,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.ownerAccent, width: 2, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.ownerAccent),
                      SizedBox(height: 12),
                      Text('கேமரா வழிகாட்டி / Capture Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ownerAccent)),
                      SizedBox(height: 4),
                      Text('எந்திரத்தை மையத்தில் வைக்கவும்', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Step 3: Price Stepper + Per Hour / Per Acre Toggle
  Widget _buildStep3PriceStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 3: வாடகைத் தொகை அமைத்தல் / Step 3: Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 24),

        // Large Price Display
        Center(
          child: Column(
            children: [
              Text('₹${_price.toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.ownerAccent)),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.ownerAccent, size: 28),
                onPressed: () => TTSService.speak('ரூபாய் ${_price.toInt()}', lang: 'ta'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // +/- Stepper (56dp target)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_price > 100) {
                    setState(() => _price -= 50);
                    TTSService.speak('ரூபாய் ${_price.toInt()}', lang: 'ta');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('-', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 64,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _price += 50);
                  TTSService.speak('ரூபாய் ${_price.toInt()}', lang: 'ta');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ownerAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Unit Toggle Buttons (Per Hour vs Per Acre)
        const Text('அலகு தேர்வு / Rate Unit:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _priceUnit = 'per_hour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _priceUnit == 'per_hour' ? AppColors.ownerAccent : Colors.grey.shade200,
                    foregroundColor: _priceUnit == 'per_hour' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('மணிநேரம் / Per Hour', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => setState(() => _priceUnit = 'per_acre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _priceUnit == 'per_acre' ? AppColors.ownerAccent : Colors.grey.shade200,
                    foregroundColor: _priceUnit == 'per_acre' ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ஏக்கர் / Per Acre', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: Availability Calendar (Tap dates red/green)
  Widget _buildStep4AvailabilityCalendar() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 4: கிடைக்கக்கூடிய நாட்கள் / Step 4: Availability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('தேதியைத் தொட்டு தடை / அனுமதி செய்யவும (பச்சை=இருக்கிறது, சிவப்பு=இல்லை)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: dates.map((date) {
            final dateKey = DateTime(date.year, date.month, date.day);
            final isBlocked = _blockedDates.contains(dateKey);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isBlocked) {
                    _blockedDates.remove(dateKey);
                  } else {
                    _blockedDates.add(dateKey);
                  }
                });
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isBlocked ? AppColors.error : AppColors.success,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${date.day}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${date.month}/${date.year}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    Icon(
                      isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 5: Optional Voice-Note Description
  Widget _buildStep5VoiceNoteDescription(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('படி 5: குரல் குறிப்பு (விருப்பமானவ) / Step 5: Voice Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        const Text('எந்திரம் பற்றி குரல் பதிவு செய்ய மைக் தொட்டுப் பேசுங்கள்', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),

        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRecordingVoiceNote = !_isRecordingVoiceNote;
                    if (!_isRecordingVoiceNote) {
                      _voiceNoteText = 'நல்ல நிலையில் உள்ள டிராக்டர். அனுபவமிக்க ஓட்டுனருடன்.';
                      TTSService.speak('குரல் பதிவு சேமிக்கப்பட்டது', lang: lang);
                    }
                  });
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _isRecordingVoiceNote ? AppColors.error : AppColors.ownerAccent,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Icon(
                    _isRecordingVoiceNote ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isRecordingVoiceNote ? 'பதிவாகிறது...' : (_voiceNoteText.isNotEmpty ? 'பதிவு முடிந்தது: "$_voiceNoteText"' : 'மைக் அழுத்தவும்'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
