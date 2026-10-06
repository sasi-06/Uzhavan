import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/machine_icons.dart';
import '../../core/widgets/page_voice_reader_button.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selected;
  bool _loading = false;
  String? _error;
  double _radiusKm = 15;
  final TtsService _tts = TtsService();

  static const _types = ['tractor', 'harvester', 'plough', 'seeder', 'sprayer'];

  static const Map<String, String> _tamilTypeNames = {
    'tractor': 'டிராக்டர்',
    'harvester': 'ஹார்வெஸ்டர் எந்திரம்',
    'plough': 'உழவு எந்திரம்',
    'seeder': 'விதைக்கும் எந்திரம்',
    'sprayer': 'தெளிப்பான்',
  };

  void _onCategorySelect(String type) {
    setState(() => _selected = type);
    final taName = _tamilTypeNames[type] ?? type;
    _tts.setLanguage('ta-IN');
    _tts.speak('$taName தேர்ந்தெடுக்கப்பட்டது. அருகில் தேட பொத்தானை அழுத்தவும்.');
  }

  Future<void> _search() async {
    if (_selected == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final state = context.read<AppState>();
      final results = await state.machineRepo.search(
        latitude: state.latitude,
        longitude: state.longitude,
        type: _selected,
        radiusKm: _radiusKm,
      );
      if (!mounted) return;

      final taName = _tamilTypeNames[_selected] ?? _selected;
      _tts.setLanguage('ta-IN');
      _tts.speak('உங்கள் பகுதியில் ${results.length} $taName கிடைக்கிறது.');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchResultsScreen(machines: results, type: _selected!),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
      _tts.setLanguage('ta-IN');
      _tts.speak('தேடல் தோல்வி. ${e.message}');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const tamilSpeechText =
        'எந்திர வகை தேர்ந்தெடுக்கவும். டிராக்டர், ஹார்வெஸ்டர், உழவு எந்திரம், விதைக்கும் எந்திரம் மற்றும் தெளிப்பான் உள்ளன. '
        'உங்களுக்கு தேவையான எந்திரத்தை தொட்டு அல்லது குரல் மூலம் தேர்வு செய்யலாம்.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'எந்திர வகை தேர்ந்தெடுக்க / Choose type',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const PageVoiceReaderButton(
                  textToRead: tamilSpeechText,
                  label: '🔊 கேளுங்கள்',
                  languageCode: 'ta-IN',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: _types.map((type) {
                  final selected = _selected == type;
                  final taLabel = _tamilTypeNames[type] ?? type;
                  return Material(
                    color: selected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    elevation: selected ? 4 : 2,
                    child: InkWell(
                      onTap: () => _onCategorySelect(type),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(machineIcon(type), size: 48, color: selected ? Colors.white : AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            taLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Search Radius:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                    onPressed: () {
                      if (_radiusKm > 5) setState(() => _radiusKm -= 5);
                    },
                  ),
                  Text('${_radiusKm.toInt()} km', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    onPressed: () {
                      if (_radiusKm < 100) setState(() => _radiusKm += 5);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _selected == null || _loading ? null : _search,
              child: _loading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('அருகில் தேடுக / Search Nearby'),
            ),
          ],
        ),
      ),
    );
  }
}
