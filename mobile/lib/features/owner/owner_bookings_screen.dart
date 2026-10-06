import 'package:flutter/foundation.dart';
import '../../core/utils/web_url_launcher_stub.dart'
    if (dart.library.html) '../../core/utils/web_url_launcher_web.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/voice_confirmation_dialog.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/booking_status_card.dart';
import '../../core/widgets/booking_workflow_tracker.dart';
import '../../core/widgets/free_open_street_map.dart';
import '../../core/widgets/diesel_audit_dialog.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});
  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<BookingModel>? _all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    // Auto-refresh when returning to screen, not polling every 2 sec.
    // Use pull-to-refresh (RefreshIndicator) for manual updates.
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<AppState>().bookingRepo.getMine();
      if (mounted) setState(() => _all = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  List<BookingModel> get _incoming => _all?.where((b) {
    final s = b.status.toLowerCase().trim();
    // Only truly pending requests are "incoming" — owner hasn't acted yet
    return s == 'pending' || s == 'requested' || s == 'new';
  }).toList() ?? [];

  List<BookingModel> get _active => _all?.where((b) {
    final s = b.status.toLowerCase().trim();
    // Everything the owner has already acted on (accepted, confirmed, in_progress, completed, cancelled)
    return s != 'pending' && s != 'requested' && s != 'new';
  }).toList() ?? [];

  Future<void> _loadAndSwitch({bool switchToActive = false}) async {
    await _load();
    if (switchToActive && mounted && _tab.index == 0) {
      _tab.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('முன்பதிவுகள் / Bookings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.ownerAccent),
            tooltip: 'புதுப்பி / Refresh',
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.ownerAccent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.ownerAccent,
          tabs: [
            Tab(text: 'கோரிக்கைகள் (${_incoming.length})'),
            Tab(text: 'செயலில் (${_active.length})'),
          ],
        ),
      ),
      body: _loading && _all == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _all == null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ElevatedButton(onPressed: _load, child: const Text('மீண்டும்')),
                ]))
              : TabBarView(controller: _tab, children: [
                  _IncomingList(bookings: _incoming, onRefresh: () => _loadAndSwitch(switchToActive: true)),
                  _ActiveList(bookings: _active, onRefresh: _load),
                ]),
    );
  }
}


LatLng _resolvePlaceCoordinates(String? placeName, double? rawLat, double? rawLng, {required bool isFarmer}) {
  final knownMap = <String, LatLng>{
    'செந்திருப்பேரை': const LatLng(8.6186, 77.9897),
    'sendhirupperai': const LatLng(8.6186, 77.9897),
    'kovilpatti': const LatLng(9.1730, 77.8680),
    'கோவில்பட்டி': const LatLng(9.1730, 77.8680),
    'thoothukudi': const LatLng(8.7642, 78.1348),
    'தூத்துக்குடி': const LatLng(8.7642, 78.1348),
    'tiruchendur': const LatLng(8.4841, 78.1248),
    'திருச்செந்தூர்': const LatLng(8.4841, 78.1248),
    'vilathikulam': const LatLng(9.1352, 78.1714),
    'விளாத்திகுளம்': const LatLng(9.1352, 78.1714),
    'coimbatore': const LatLng(11.0168, 76.9558),
    'கோயம்புத்தூர்': const LatLng(11.0168, 76.9558),
    'pollachi': const LatLng(10.6609, 77.0048),
    'பொள்ளாச்சி': const LatLng(10.6609, 77.0048),
    'madurai': const LatLng(9.9252, 78.1198),
    'மதுரை': const LatLng(9.9252, 78.1198),
    'chennai': const LatLng(13.0827, 80.2707),
    'சென்னை': const LatLng(13.0827, 80.2707),
  };

  if (placeName != null && placeName.isNotEmpty) {
    final lower = placeName.toLowerCase();
    for (final entry in knownMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
  }

  if (rawLat != null && rawLng != null && rawLat != 0.0 && rawLng != 0.0 &&
      !(rawLat == 13.0827 && rawLng == 80.2707)) {
    return LatLng(rawLat, rawLng);
  }

  return isFarmer ? const LatLng(8.6186, 77.9897) : const LatLng(8.7642, 78.1348);
}

void _showFarmerLocationMap(BuildContext context, BookingModel booking) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _FarmerLocationModalSheet(booking: booking),
  );
}

class _FarmerLocationModalSheet extends StatefulWidget {
  const _FarmerLocationModalSheet({required this.booking});
  final BookingModel booking;

  @override
  State<_FarmerLocationModalSheet> createState() => _FarmerLocationModalSheetState();
}

class _FarmerLocationModalSheetState extends State<_FarmerLocationModalSheet> {
  double? _liveOwnerLat;
  double? _liveOwnerLng;
  bool _fetchingGps = true;

  @override
  void initState() {
    super.initState();
    _getLiveLocation();
  }

  Future<void> _getLiveLocation() async {
    final appState = context.read<AppState>();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission perm = LocationPermission.denied;
      if (serviceEnabled) {
        perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
      }
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _liveOwnerLat = pos.latitude;
            _liveOwnerLng = pos.longitude;
          });
          appState.setLocation(pos.latitude, pos.longitude);
        }
      } else {
        // Fallback to appState stored coordinates
        if (mounted) {
          setState(() {
            _liveOwnerLat = appState.latitude;
            _liveOwnerLng = appState.longitude;
          });
        }
      }
    } catch (e) {
      // Fallback to appState on any error
      if (mounted) {
        setState(() {
          _liveOwnerLat = appState.latitude;
          _liveOwnerLng = appState.longitude;
        });
      }
    } finally {
      if (mounted) setState(() => _fetchingGps = false);
    }
  }

  void _openDirections(double startLat, double startLng, double destLat, double destLng) {
    final url = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$destLat,$destLng&travelmode=driving';
    try {
      openWebWindow(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('கூகுள் வரைபடம் திறக்கப்படுகிறது... / Opening Google Maps Directions...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('வரைபடம் திறப்பதில் பிழை / Error opening map: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final village = widget.booking.farmerVillage ?? 'செந்திருப்பேரை';
    final farmerLoc = _resolvePlaceCoordinates(village, widget.booking.farmerLat, widget.booking.farmerLng, isFarmer: true);
    
    // Use live GPS first, then appState fallback
    final appState = context.read<AppState>();
    var ownerLat = _liveOwnerLat ?? appState.latitude ?? 8.7642;
    var ownerLng = _liveOwnerLng ?? appState.longitude ?? 78.1348;

    final farmerLat = farmerLoc.latitude;
    final farmerLng = farmerLoc.longitude;

    if ((farmerLat - ownerLat).abs() < 0.005 && (farmerLng - ownerLng).abs() < 0.005) {
      ownerLat = farmerLat + 0.05;
      ownerLng = farmerLng + 0.05;
    }

    final farmerName = widget.booking.renter?.name.isNotEmpty == true ? widget.booking.renter!.name : 'விவசாயி / Farmer';
    final farmerPhone = widget.booking.renter?.phone ?? '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'பாதை இருப்பிடம் / Route to Farmer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('$farmerName ($village)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ownerAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ownerAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _fetchingGps ? 'GPS பெறுகிறது...' : 'இயந்திர உரிமையாளர் (Live GPS):',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${ownerLat.toStringAsFixed(4)}, ${ownerLng.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text('விவசாயி (Farmer):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$village (${farmerLat.toStringAsFixed(4)}, ${farmerLng.toStringAsFixed(4)})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FreeOpenStreetMap(
              latitude: (ownerLat + farmerLat) / 2,
              longitude: (ownerLng + farmerLng) / 2,
              startLatitude: ownerLat,
              startLongitude: ownerLng,
              startTitle: 'உரிமையாளர் GPS',
              destLatitude: farmerLat,
              destLongitude: farmerLng,
              destTitle: 'விவசாயி / Farmer',
              initialZoom: 11,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _openDirections(ownerLat, ownerLng, farmerLat, farmerLng),
                  icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'வழித்தடம் / Directions',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (farmerPhone.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ownerAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      openWebWindow('tel:$farmerPhone');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('அழைக்கிறது / Calling $farmerPhone...')),
                      );
                    },
                    icon: const Icon(Icons.phone_rounded, color: Colors.white),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'அழைக்க / Call',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomingList extends StatelessWidget {
  const _IncomingList({required this.bookings, required this.onRefresh});
  final List<BookingModel> bookings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.inbox_rounded, size: 80, color: AppColors.divider),
                const SizedBox(height: 16),
                const Text('புதிய கோரிக்கைகள் இல்லை', style: TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('விவசாயிகள் அனுப்பும் முன்பதிவு கோரிக்கைகள் இங்கு தோன்றும்', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('புதுப்பி / Refresh Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ownerAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          return _IncomingCard(booking: b, onRefresh: onRefresh);
        },
      ),
    );
  }
}

class _IncomingCard extends StatefulWidget {
  const _IncomingCard({required this.booking, required this.onRefresh});
  final BookingModel booking;
  final Future<void> Function() onRefresh;
  @override
  State<_IncomingCard> createState() => _IncomingCardState();
}

class _IncomingCardState extends State<_IncomingCard> {
  bool _accepting = false;
  bool _declining = false;
  final TtsService _tts = TtsService();
  final DateFormat _df = DateFormat('dd MMM');

  void _speak(String text) { _tts.setLanguage('ta-IN'); _tts.speak(text); }

  Future<void> _accept() async {
    final confirmed = await VoiceConfirmationDialog.show(
      context,
      title: 'முன்பதிவு ஏற்கவா? / Accept Request?',
      message: '${widget.booking.renter?.name ?? "விவசாயி"} கோரிக்கையை ஏற்க விரும்புகிறீர்களா?',
      actionLabel: 'ஏற்றுக்கொள் / ACCEPT',
    );
    if (confirmed != true) return;

    _speak('ஏற்றுக்கொள்கிறோம்');
    setState(() => _accepting = true);
    try {
      await context.read<AppState>().bookingRepo.ownerConfirm(widget.booking.id);
      // Await the refresh so the list is fully reloaded (and tab switches) before we clear the spinner
      await widget.onRefresh();
    } finally { if (mounted) setState(() => _accepting = false); }
  }

  Future<void> _decline() async {
    final confirmed = await VoiceConfirmationDialog.show(
      context,
      title: 'முன்பதிவு நிராகரிக்கவா? / Decline Request?',
      message: '${widget.booking.renter?.name ?? "விவசாயி"} கோரிக்கையை நிராகரிக்க விரும்புகிறீர்களா?',
      actionLabel: 'நிராகரி / DECLINE',
    );
    if (confirmed != true) return;

    _speak('மறுக்கிறோம்');
    setState(() => _declining = true);
    try {
      await context.read<AppState>().bookingRepo.cancel(widget.booking.id);
      await widget.onRefresh();
    } finally { if (mounted) setState(() => _declining = false); }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final renter = b.renter;

    return GestureDetector(
      onTap: () => _speak('${renter?.name ?? 'விவசாயி'}, ${_df.format(b.startDate)} முதல் ${_df.format(b.endDate)} வரை கோரிக்கை'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8)],
          border: Border.all(color: AppColors.pendingIcon.withValues(alpha: 0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              child: const Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(renter?.name ?? 'விவசாயி', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${_df.format(b.startDate)} – ${_df.format(b.endDate)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.pendingIcon.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: const Text('காத்திருக்கிறது', style: TextStyle(color: AppColors.pendingIcon, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          // Farmer Location Tile
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.ownerAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.ownerAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.ownerAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'விவசாயி இருப்பிடம் / Farmer Location',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      Text(
                        b.farmerVillage != null && b.farmerVillage!.isNotEmpty
                            ? b.farmerVillage!
                            : (b.farmerLat != null && b.farmerLng != null
                                ? '${b.farmerLat!.toStringAsFixed(3)}, ${b.farmerLng!.toStringAsFixed(3)}'
                                : 'இருப்பிடம் கிடைக்கிறது'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.ownerAccent,
                    side: const BorderSide(color: AppColors.ownerAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => _showFarmerLocationMap(context, b),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('வரைபடம்', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _declining ? null : _decline,
              icon: _declining ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.close_rounded),
              label: const Text('மறு', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _accepting ? null : _accept,
              icon: _accepting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: const Text('ஏற்கு', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _ActiveList extends StatelessWidget {
  const _ActiveList({required this.bookings, required this.onRefresh});
  final List<BookingModel> bookings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 300,
            child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.event_note_rounded, size: 80, color: AppColors.divider),
              SizedBox(height: 16),
              Text('செயலில் உள்ள முன்பதிவுகள் இல்லை', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              SizedBox(height: 8),
              Text('கோரிக்கைகளை ஏற்றதும் இங்கு தோன்றும்', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ])),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          return Column(children: [
            BookingStatusCard(
              booking: b,
              showRenterName: true,
              onTap: () => _showFarmerLocationMap(context, b),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.ownerAccent,
                        side: const BorderSide(color: AppColors.ownerAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _showFarmerLocationMap(context, b),
                      icon: const Icon(Icons.location_on_rounded, size: 16),
                      label: Flexible(
                        child: Text(
                          'வரைபடம்: ${b.farmerVillage ?? "Map"}',
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        final durationHours = b.endDate.difference(b.startDate).inHours;
                        DieselAuditDialog.show(
                          context,
                          bookingId: b.id,
                          machineTitle: b.machineType ?? 'டிராக்டர் / Tractor',
                          initialHours: durationHours > 0 ? durationHours.toDouble() : 3.0,
                        );
                      },
                      icon: const Icon(Icons.local_gas_station_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: const Flexible(
                        child: Text(
                          'டீசல் சரிபார் / Fuel Audit',
                          maxLines: 1,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BookingWorkflowTracker(
              booking: b,
              isOwner: true,
              onStatusUpdated: onRefresh,
            ),
          ]);
        },
      ),
    );
  }
}
