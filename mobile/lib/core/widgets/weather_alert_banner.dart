/// Uzhavan — Weather Alert Banner Widget
///
/// Shows:
///  • A 7-day horizontal mini weather strip
///  • A full workability card for the selected booking date
///  • TTS voice warning in Tamil/Telugu/Hindi
///  • Skeleton shimmer while loading

import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class WeatherAlertBanner extends StatefulWidget {
  const WeatherAlertBanner({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.machineType,
    required this.selectedDate,
    this.lang = 'ta',
    this.onForecastLoaded,
  });

  final double latitude;
  final double longitude;
  final String machineType;
  final DateTime selectedDate;
  final String lang;

  /// Called when forecast is fetched — lets parent react
  final void Function(WeatherForecast forecast)? onForecastLoaded;

  @override
  State<WeatherAlertBanner> createState() => _WeatherAlertBannerState();
}

class _WeatherAlertBannerState extends State<WeatherAlertBanner>
    with SingleTickerProviderStateMixin {
  WeatherForecast? _forecast;
  bool _loading = true;
  bool _hasError = false;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    _fetchWeather();
  }

  @override
  void didUpdateWidget(WeatherAlertBanner old) {
    super.didUpdateWidget(old);
    // Re-fetch if location or machine type changes
    if (old.latitude != widget.latitude ||
        old.longitude != widget.longitude ||
        old.machineType != widget.machineType) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final forecast = await WeatherService.instance.fetchForecast(
        lat: widget.latitude,
        lng: widget.longitude,
        machineType: widget.machineType,
      );
      if (!mounted) return;
      if (forecast == null) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
        return;
      }
      setState(() {
        _forecast = forecast;
        _loading = false;
      });
      widget.onForecastLoaded?.call(forecast);
      _speakWarning(forecast);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _speakWarning(WeatherForecast forecast) {
    final day = forecast.forDate(widget.selectedDate);
    if (day == null) return;
    final lang = widget.lang;
    String message;
    switch (day.workability) {
      case SoilWorkabilityLevel.poor:
        message = lang == 'ta'
            ? '${_tamilDate(widget.selectedDate)} தேதி கடும் மழை எதிர்பார்க்கப்படுகிறது. ${_tamilMachineType(widget.machineType)} முன்பதிவு செய்வதை கவனமாக பரிசீலியுங்கள்.'
            : lang == 'te'
                ? 'ఆ రోజు భారీ వర్షం అంచనా వేయబడింది. బుకింగ్ జాగ్రత్తగా పరిశీలించండి.'
                : 'उस दिन भारी बारिश का अनुमान है। मशीन बुकिंग सावधानी से करें।';
      case SoilWorkabilityLevel.caution:
        message = lang == 'ta'
            ? '${_tamilDate(widget.selectedDate)} தேதி சிறிய மழை இருக்கலாம். உரிமையாளரிடம் உறுதிப்படுத்துங்கள்.'
            : lang == 'te'
                ? 'తేలికపాటి వర్షం అంచనా. యజమానితో నిర్ధారించండి.'
                : 'हल्की बारिश का अनुमान है। मालिक से पुष्टि करें।';
      case SoilWorkabilityLevel.good:
        message = lang == 'ta'
            ? '${_tamilDate(widget.selectedDate)} தேதி வானிலை நல்லது. ${_tamilMachineType(widget.machineType)} பயன்படுத்த ஏற்ற நேரம்.'
            : lang == 'te'
                ? 'వాతావరణం అనుకూలంగా ఉంది. మెషిన్ ఉపయోగానికి మంచి సమయం.'
                : 'मौसम अनुकूल है। मशीन उपयोग के लिए उचित समय।';
      default:
        return;
    }
    TTSService.speak(message, lang: lang);
  }

  String _tamilDate(DateTime d) => '${d.day}/${d.month}';
  String _tamilMachineType(String t) {
    switch (t.toLowerCase()) {
      case 'rotavator': return 'ரோட்டவேட்டர்';
      case 'harvester': return 'அறுவடை இயந்திரம்';
      case 'tractor': return 'டிராக்டர்';
      default: return 'எந்திரம்';
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_hasError) return _buildErrorCard();
    if (_forecast == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 10),
        _buildWeatherStrip(),
        const SizedBox(height: 12),
        _buildWorkabilityCard(),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.cloud_rounded, size: 18, color: AppColors.info),
        const SizedBox(width: 6),
        const Text(
          'வானிலை நிலை / Weather & Soil',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            if (_forecast != null) _speakWarning(_forecast!);
          },
          child: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildWeatherStrip() {
    final days = _forecast!.days;
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.date.year == widget.selectedDate.year &&
              day.date.month == widget.selectedDate.month &&
              day.date.day == widget.selectedDate.day;
          return _DayChip(day: day, isSelected: isSelected);
        },
      ),
    );
  }

  Widget _buildWorkabilityCard() {
    final day = _forecast!.forDate(widget.selectedDate);
    if (day == null) {
      return _buildNoDataCard();
    }
    return _WorkabilityCard(day: day, machineType: widget.machineType);
  }

  Widget _buildNoDataCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.grey),
          SizedBox(width: 10),
          Text('Selected date is beyond 7-day forecast range.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Opacity(
        opacity: _shimmerAnim.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (_) => Container(
                  width: 52,
                  height: 82,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'வானிலை தகவல் கிடைக்கவில்லை / Weather unavailable (check internet)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          GestureDetector(
            onTap: _fetchWeather,
            child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Day Chip ──────────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.isSelected});
  final DayWeather day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _workabilityColor(day.workability);
    final bgColor = isSelected ? color : color.withValues(alpha: 0.1);
    final textColor = isSelected ? Colors.white : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _dayLabel(day.date),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
          Text(
            _weatherEmoji(day.weatherCode),
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            '${day.precipProbMax}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}\n${d.day}/${d.month}';
  }

  String _weatherEmoji(int code) {
    if (code == 0 || code == 1) return '☀️';
    if (code == 2) return '⛅';
    if (code == 3) return '☁️';
    if (code >= 45 && code <= 48) return '🌫️';
    if (code >= 51 && code <= 55) return '🌦️';
    if (code >= 61 && code <= 67) return '🌧️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 95) return '⛈️';
    return '🌤️';
  }
}

// ── Workability Card ──────────────────────────────────────────────────────────

class _WorkabilityCard extends StatelessWidget {
  const _WorkabilityCard({required this.day, required this.machineType});
  final DayWeather day;
  final String machineType;

  @override
  Widget build(BuildContext context) {
    final color = _workabilityColor(day.workability);
    final bgColor = color.withValues(alpha: 0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_workabilityIcon(day.workability), color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workabilityTitle(day.workability),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      '${day.weatherLabelTamil} / ${day.weatherLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.water_drop_rounded,
                value: '${day.precipSumMm.toStringAsFixed(1)} mm',
                label: 'மழை / Rain',
                color: color,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.percent_rounded,
                value: '${day.precipProbMax}%',
                label: 'வாய்ப்பு / Chance',
                color: color,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.air_rounded,
                value: '${day.windspeedMaxKmh.toStringAsFixed(0)} km/h',
                label: 'காற்று / Wind',
                color: color,
              ),
            ],
          ),
          if (day.workability != SoilWorkabilityLevel.good) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.agriculture_rounded, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _machineWarning(day.workability, machineType),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _workabilityTitle(SoilWorkabilityLevel level) {
    switch (level) {
      case SoilWorkabilityLevel.good:
        return '✅ மண் நிலை நல்லது / Soil Conditions Good';
      case SoilWorkabilityLevel.caution:
        return '⚠️ கவனம் தேவை / Use Caution';
      case SoilWorkabilityLevel.poor:
        return '❌ இயந்திரம் பயன்படுத்த தகுதியற்றது / Poor Conditions';
      default:
        return '📡 வானிலை / Weather';
    }
  }

  String _machineWarning(SoilWorkabilityLevel level, String machineType) {
    final strictMachines = {'rotavator', 'harvester', 'cultivator', 'thresher'};
    final isStrict = strictMachines.contains(machineType.toLowerCase());
    if (level == SoilWorkabilityLevel.poor) {
      return isStrict
          ? 'கனமழையில் ${machineType} பயன்படுத்தினால் மண் சேதமாகலாம் மற்றும் இயந்திரம் மாட்டிக்கொள்ளலாம். உரிமையாளரிடம் ஒருமுறை கேளுங்கள்.'
          : 'Heavy rain forecast. Confirm with the machine owner before booking.';
    }
    return isStrict
        ? 'சிறிய மழை இருக்கலாம். ${machineType} உரிமையாளரிடம் உறுதிப்படுத்திக்கொள்ளுங்கள்.'
        : 'Light rain possible. Double-check with the owner before finalising.';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _workabilityColor(SoilWorkabilityLevel level) {
  switch (level) {
    case SoilWorkabilityLevel.good:
      return AppColors.success;
    case SoilWorkabilityLevel.caution:
      return AppColors.warning;
    case SoilWorkabilityLevel.poor:
      return AppColors.error;
    default:
      return AppColors.info;
  }
}

IconData _workabilityIcon(SoilWorkabilityLevel level) {
  switch (level) {
    case SoilWorkabilityLevel.good:
      return Icons.check_circle_rounded;
    case SoilWorkabilityLevel.caution:
      return Icons.warning_amber_rounded;
    case SoilWorkabilityLevel.poor:
      return Icons.dangerous_rounded;
    default:
      return Icons.cloud_queue_rounded;
  }
}
