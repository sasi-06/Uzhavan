import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/utils/machine_icons.dart';
import '../../core/widgets/status_banner.dart';
import '../../core/widgets/page_voice_reader_button.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<BookingModel>? _bookings;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<AppState>().bookingRepo.getMine();
      setState(() => _bookings = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  StatusType _statusType(String status) => switch (status) {
        'confirmed' || 'completed' => StatusType.success,
        'cancelled' => StatusType.error,
        _ => StatusType.pending,
      };

  String _statusMessage(BookingModel b) {
    final type = b.machineType ?? 'எந்திரம்';
    return switch (b.status) {
      'confirmed' => '$type — உறுதி செய்யப்பட்டது',
      'completed' => '$type — நிறைவுற்றது',
      'cancelled' => '$type — ரத்து செய்யப்பட்டது',
      _ => '$type — உரிமையாளர் ஒப்புதலுக்கு காத்திருக்கிறது',
    };
  }

  String _buildPageSpeech(List<BookingModel> list) {
    if (list.isEmpty) {
      return 'என் முன்பதிவு பக்கம். உங்களிடம் தற்சமயம் முன்பதிவுகள் எதுவும் இல்லை.';
    }
    final count = list.length;
    final summaries = list.map((b) => _statusMessage(b)).join('. ');
    return 'என் முன்பதிவு பக்கம். உங்களிடம் $count முன்பதிவுகள் உள்ளன. விபரங்கள்: $summaries.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('மீண்டும் முயல / Retry')),
            ],
          ),
        ),
      );
    }
    final bookings = _bookings ?? [];
    final speechText = _buildPageSpeech(bookings);

    return SafeArea(
      child: Column(
        children: [
          // Header Bar with Tamil Voice Reader
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'என் முன்பதிவு / My Bookings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PageVoiceReaderButton(
                  textToRead: speechText,
                  label: '🔊 கேளுங்கள்',
                  languageCode: 'ta-IN',
                ),
              ],
            ),
          ),
          Expanded(
            child: bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('முன்பதிவுகள் எதுவும் இல்லை', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        for (final b in bookings) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              StatusBanner(
                                type: _statusType(b.status),
                                icon: machineIcon(b.machineType ?? 'tractor'),
                                message: _statusMessage(b),
                              ),
                              if (b.renter != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
                                  child: Text('Requested by: ${b.renter!.name.isNotEmpty ? b.renter!.name : 'Unknown'} (${b.renter!.phone})', 
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
