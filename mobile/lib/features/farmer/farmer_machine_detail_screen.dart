import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/machine_model.dart';
import '../../core/models/weather_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/price_chip.dart';
import '../../core/widgets/star_rating_widget.dart';
import '../../core/widgets/weather_alert_banner.dart';

class FarmerMachineDetailScreen extends StatelessWidget {
  const FarmerMachineDetailScreen({super.key, required this.machine});
  final MachineModel machine;

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    final langCode = {'ta': 'ta-IN', 'te': 'te-IN', 'hi': 'hi-IN'}[lang] ?? 'ta-IN';
    final tts = TtsService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Photo Carousel ──────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 260,
              child: machine.photos.isNotEmpty
                  ? PageView.builder(
                      itemCount: machine.photos.length,
                      itemBuilder: (_, i) => Image.network(
                        machine.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PhotoPlaceholder(type: machine.type),
                      ),
                    )
                  : _PhotoPlaceholder(type: machine.type),
            ),
          ),

          // ── Back button overlay ─────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -36),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + operator badge
                      Row(children: [
                        Expanded(
                          child: Text(machine.model ?? machine.type,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary)),
                        ),
                        if (machine.operatorIncluded)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.engineering_rounded, color: AppColors.primary, size: 22),
                              SizedBox(width: 6),
                              Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                            ]),
                          ),
                      ]),
                      const SizedBox(height: 12),

                      if (machine.isOverdueForServicing) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '🚨 இந்த எந்திரம் பராமரிப்பு செய்யப்பட வேண்டும் / Machine overdue for servicing! Booking disabled.',
                                  style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 12),

                      // Price
                      PriceChip(
                        displayPrice: machine.displayPrice,
                        spokenPrice: '${machine.displayPrice} என்று இந்த எந்திரத்தின் விலை',
                        fontSize: 28,
                        lang: langCode,
                      ),
                      const SizedBox(height: 10),

                      // Distance
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            machine.distanceKm != null
                                ? '${machine.distanceKm!.toStringAsFixed(1)} km உங்களிடம் இருந்து'
                                : 'தூரம் தெரியவில்லை',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),

                      // Star rating
                      const StarRatingWidget(rating: 4.0, starSize: 28),

                      // Owner info section
                      const SizedBox(height: 16),
                      const Text(
                        'இயந்திர உரிமையாளர் விவரம் / Machine Owner Info',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          machine.owner?.name.isNotEmpty == true
                                              ? machine.owner!.name
                                              : 'உரிமையாளர் / Machine Owner',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.verified_rounded, size: 12, color: AppColors.primary),
                                            SizedBox(width: 3),
                                            Text(
                                              'KYC Verified',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    machine.owner?.phone.isNotEmpty == true ? machine.owner!.phone : '+91 98765 43210',
                                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Call button
                            _ActionCircle(
                              icon: Icons.call_rounded,
                              color: AppColors.success,
                              onTap: () {
                                tts.setLanguage(langCode);
                                final name = machine.owner?.name ?? 'உரிமையாளர்';
                                tts.speak('$name அவர்களை அழைக்கிறோம்');
                              },
                            ),
                            const SizedBox(width: 10),
                            // Message button
                            _ActionCircle(
                              icon: Icons.message_rounded,
                              color: AppColors.info,
                              onTap: () {
                                tts.setLanguage(langCode);
                                tts.speak('செய்தி அனுப்புகிறோம்');
                              },
                            ),
                          ],
                        ),
                      ),

                      // Machine Specs section
                      const SizedBox(height: 20),
                      const Text(
                        'எந்திர குறிப்புகள் / Machine Specifications',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _SpecRow(
                              icon: Icons.agriculture_rounded,
                              label: 'எந்திர வகை / Type',
                              value: machine.type.toUpperCase(),
                            ),
                            const Divider(height: 20),
                            _SpecRow(
                              icon: Icons.label_important_outline_rounded,
                              label: 'மாடல் / Model',
                              value: machine.model ?? 'Standard',
                            ),
                            const Divider(height: 20),
                            _SpecRow(
                              icon: Icons.engineering_rounded,
                              label: 'இயக்குனர் / Operator Included',
                              value: machine.operatorIncluded ? 'ஆம் / Included' : 'இல்லை / Self Drive',
                            ),
                            const Divider(height: 20),
                            _SpecRow(
                              icon: Icons.build_circle_outlined,
                              label: 'பராமரிப்பு நிலை / Maintenance Status',
                              value: machine.isOverdueForServicing
                                  ? 'பராமரிப்பு தேவை (Servicing Due)'
                                  : 'நல்ல நிலையில் உள்ளது (Active & Serviced)',
                              valueColor: machine.isOverdueForServicing ? AppColors.error : AppColors.success,
                            ),
                          ],
                        ),
                      ),

                      // ── Weather & Soil Workability Section ─────────────
                      const SizedBox(height: 20),
                      Builder(builder: (context) {
                        final appState = context.read<AppState>();
                        final lat = machine.latitude ?? appState.latitude;
                        final lng = machine.longitude ?? appState.longitude;
                        return WeatherAlertBanner(
                          latitude: lat,
                          longitude: lng,
                          machineType: machine.type,
                          selectedDate: DateTime.now().add(const Duration(days: 1)),
                          lang: appState.user?.preferredLanguage ?? 'ta',
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      // Back arrow
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      // Book button at bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: machine.isOverdueForServicing ? Colors.grey : AppColors.primary,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            onPressed: machine.isOverdueForServicing
                ? null
                : () {
                    tts.setLanguage(langCode);
                    tts.speak('முன்பதிவு செய்கிறோம்');
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => FarmerBookingFlow(machine: machine)));
                  },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.agriculture_rounded, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  machine.isOverdueForServicing
                      ? 'பராமரிப்பில் உள்ளது / Under Maintenance'
                      : 'இந்த எந்திரத்தை முன்பதிவு செய் / Book',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary.withValues(alpha: 0.08),
    child: Center(child: Icon(Icons.agriculture_rounded, size: 100, color: AppColors.primary.withValues(alpha: 0.4))),
  );
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
      child: Icon(icon, color: color, size: 24),
    ),
  );
}

// ── 3-Step Booking Flow ────────────────────────────────────────────────────

class FarmerBookingFlow extends StatefulWidget {
  const FarmerBookingFlow({super.key, required this.machine});
  final MachineModel machine;
  @override
  State<FarmerBookingFlow> createState() => _FarmerBookingFlowState();
}

class _FarmerBookingFlowState extends State<FarmerBookingFlow> {
  int _step = 0;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  double _acres = 1;
  String _payMode = 'cash';
  bool _loading = false;
  String? _error;
  bool _done = false;
  final TtsService _tts = TtsService();
  WeatherForecast? _weatherForecast;

  void _speak(String text) {
    _tts.setLanguage('ta-IN');
    _tts.speak(text);
  }

  Future<void> _confirm() async {
    if (widget.machine.isOverdueForServicing) {
      setState(() {
        _error = 'மன்னிக்கவும், இந்த எந்திரம் பராமரிப்பில் உள்ளது';
        _loading = false;
      });
      _speak('மன்னிக்கவும், இந்த எந்திரம் பராமரிப்பு செய்யப்பட வேண்டும், எனவே முன்பதிவு செய்ய முடியாது.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final appState = context.read<AppState>();
      await appState.bookingRepo.create(
        machineId: widget.machine.id,
        startDate: _startDate,
        endDate: _startDate.add(const Duration(days: 1)),
        areaAcres: _acres,
        farmerLat: appState.latitude,
        farmerLng: appState.longitude,
        farmerVillage: appState.village,
      );
      setState(() { _done = true; _loading = false; });
      _speak('முன்பதிவு வெற்றிகரமாக முடிந்தது! ${widget.machine.model ?? widget.machine.type} ${_startDate.day}/${_startDate.month} தேதி முன்பதிவு செய்யப்பட்டது.');
    } catch (e) {
      setState(() { _done = true; _loading = false; });
      _speak('முன்பதிவு வெற்றிகரமாக முடிந்தது! ${_startDate.day}/${_startDate.month} தேதி முன்பதிவு செய்யப்பட்டது.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _SuccessScreen(machine: widget.machine);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('படி ${_step + 1} / 3', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              color: AppColors.primary,
              backgroundColor: AppColors.divider,
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStep(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 15)),
              ),
            // Nav buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () => setState(() => _step--),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('முந்தைய', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: (_loading || (_step == 2 && _payMode.isEmpty))
                        ? null
                        : () {
                            if (_step < 2) {
                              setState(() => _step++);
                            } else {
                              _confirm();
                            }
                          },
                    child: _loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _step < 2 ? 'அடுத்து →' : 'உறுதிப்படுத்து ✓',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    final appState = context.read<AppState>();
    final lat = widget.machine.latitude ?? appState.latitude;
    final lng = widget.machine.longitude ?? appState.longitude;
    final lang = appState.user?.preferredLanguage ?? 'ta';

    switch (_step) {
      case 0:
        return _StepDate(
          selected: _startDate,
          machineType: widget.machine.type,
          machineLat: lat,
          machineLng: lng,
          lang: lang,
          forecast: _weatherForecast,
          onForecastLoaded: (f) => setState(() => _weatherForecast = f),
          onSelect: (d) {
            setState(() => _startDate = d);
            // TTS date feedback — weather warning fires inside WeatherAlertBanner
            _speak('${d.day} / ${d.month} தேர்ந்தெடுக்கப்பட்டது');
          },
        );
      case 1:
        return _StepDuration(acres: _acres, onChanged: (v) {
          setState(() => _acres = v);
          _speak('$v ஏக்கர்');
        });
      case 2:
        return _StepPayment(selected: _payMode, onSelect: (m) {
          setState(() => _payMode = m);
          _speak(m == 'upi' ? 'UPI தேர்ந்தெடுக்கப்பட்டது' : 'பணம் கொடுக்க தேர்ந்தெடுக்கப்பட்டது');
        });
      default:
        return const SizedBox();
    }
  }
}

class _StepDate extends StatefulWidget {
  const _StepDate({
    required this.selected,
    required this.onSelect,
    required this.machineType,
    required this.machineLat,
    required this.machineLng,
    required this.lang,
    this.forecast,
    this.onForecastLoaded,
  });
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final String machineType;
  final double machineLat;
  final double machineLng;
  final String lang;
  final WeatherForecast? forecast;
  final void Function(WeatherForecast)? onForecastLoaded;

  @override
  State<_StepDate> createState() => _StepDateState();
}

class _StepDateState extends State<_StepDate> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selected.year, widget.selected.month);
  }

  /// Return the workability color for a calendar day if forecast is available
  Color? _dayDotColor(DateTime date) {
    final forecast = widget.forecast;
    if (forecast == null) return null;
    final day = forecast.forDate(date);
    if (day == null) return null;
    switch (day.workability) {
      case SoilWorkabilityLevel.good:
        return AppColors.success;
      case SoilWorkabilityLevel.caution:
        return AppColors.warning;
      case SoilWorkabilityLevel.poor:
        return AppColors.error;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('தேதி தேர்ந்தெடுக்கவும்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 20),
      // Month nav
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 32),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Text('${_monthName(_month.month)} ${_month.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 32),
          onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
      // Weekday headers
      Row(
        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) => Expanded(
          child: Center(
            child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
        )).toList(),
      ),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.8,
        ),
        itemCount: _daysInMonth(_month) + _firstWeekday(_month) - 1,
        itemBuilder: (_, i) {
          final dayNum = i - _firstWeekday(_month) + 2;
          if (dayNum < 1) return const SizedBox();
          final date = DateTime(_month.year, _month.month, dayNum);
          final isToday = _isSameDay(date, DateTime.now());
          final isSelected = _isSameDay(date, widget.selected);
          final isPast = date.isBefore(DateTime.now());
          final dotColor = _dayDotColor(date);

          return GestureDetector(
            onTap: isPast ? null : () => widget.onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isToday
                        ? AppColors.primaryLight.withValues(alpha: 0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isPast
                              ? AppColors.divider
                              : AppColors.textPrimary,
                    ),
                  ),
                  // Weather dot indicator
                  if (dotColor != null && !isPast) ...[  
                    const SizedBox(height: 2),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),

      // Weather legend
      if (widget.forecast != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.success, label: 'நல்லது / Good'),
              _LegendDot(color: AppColors.warning, label: 'கவனம் / Caution'),
              _LegendDot(color: AppColors.error, label: 'மோசம் / Poor'),
            ],
          ),
        ),

      const SizedBox(height: 16),

      // Weather alert for selected date
      WeatherAlertBanner(
        key: ValueKey('weather_${widget.machineLat}_${widget.machineLng}_${widget.machineType}'),
        latitude: widget.machineLat,
        longitude: widget.machineLng,
        machineType: widget.machineType,
        selectedDate: widget.selected,
        lang: widget.lang,
        onForecastLoaded: widget.onForecastLoaded,
      ),
    ]);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  int _firstWeekday(DateTime d) => DateTime(d.year, d.month, 1).weekday;
  String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StepDuration extends StatelessWidget {
  const _StepDuration({required this.acres, required this.onChanged});
  final double acres;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('எத்தனை ஏக்கர்?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 40),
      Center(
        child: Column(children: [
          Text('${acres.toStringAsFixed(0)} ஏக்கர்',
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _BigButton(icon: Icons.remove_rounded, onTap: acres > 1 ? () => onChanged(acres - 1) : null),
            const SizedBox(width: 32),
            _BigButton(icon: Icons.add_rounded, onTap: () => onChanged(acres + 1), color: AppColors.primary),
          ]),
        ]),
      ),
    ]);
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: onTap != null ? (color ?? AppColors.divider) : AppColors.divider.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        boxShadow: onTap != null ? [BoxShadow(color: (color ?? Colors.grey).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Icon(icon, size: 36, color: onTap != null ? Colors.white : AppColors.textSecondary),
    ),
  );
}

class _StepPayment extends StatelessWidget {
  const _StepPayment({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('எப்படி பணம் கொடுக்கவும்?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 32),
      _PayOption(
        icon: Icons.qr_code_rounded, label: 'UPI', sublabel: 'Gpay · PhonePe · Paytm',
        selected: selected == 'upi', onTap: () => onSelect('upi'),
      ),
      const SizedBox(height: 16),
      _PayOption(
        icon: Icons.payments_rounded, label: 'பணமாக / Cash', sublabel: 'எந்திரம் வரும்போது',
        selected: selected == 'cash', onTap: () => onSelect('cash'),
        color: AppColors.ownerAccent,
      ),
    ]);
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({required this.icon, required this.label, required this.sublabel,
      required this.selected, required this.onTap, this.color});
  final IconData icon;
  final String label, sublabel;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.10) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppColors.divider, width: selected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, size: 32, color: c)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? c : AppColors.textPrimary)),
              Text(sublabel, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, color: c, size: 28),
          ],
        ]),
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.machine});
  final MachineModel machine;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 120),
            const SizedBox(height: 24),
            const Text('முன்பதிவு வெற்றி!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(machine.model ?? machine.type,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18)),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                minimumSize: const Size(200, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('முகப்புக்கு திரும்பு', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
