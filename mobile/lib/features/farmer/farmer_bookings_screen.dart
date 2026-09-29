import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/booking_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/booking_status_card.dart';
import '../../core/widgets/star_rating_widget.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/booking_workflow_tracker.dart';
import '../../core/widgets/voice_confirmation_dialog.dart';

class FarmerBookingsScreen extends StatefulWidget {
  const FarmerBookingsScreen({super.key});
  @override
  State<FarmerBookingsScreen> createState() => _FarmerBookingsScreenState();
}

class _FarmerBookingsScreenState extends State<FarmerBookingsScreen> {
  List<BookingModel>? _bookings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<AppState>().bookingRepo.getMine();
      setState(() => _bookings = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'என் முன்பதிவுகள் / Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: AppColors.error, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('மீண்டும் முயல / Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : (_bookings?.isEmpty ?? true)
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_note_rounded, size: 56, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'முன்பதிவுகள் எதுவும் இல்லை',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'No bookings found. Speak or search to book a machine.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _bookings!.length,
                        itemBuilder: (_, i) {
                          final b = _bookings![i];
                          return BookingStatusCard(
                            booking: b,
                            onTap: () => _openDetail(b),
                          );
                        },
                      ),
                    ),
    );
  }

  void _openDetail(BookingModel b) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BookingDetailScreen(booking: b, onRefresh: _load),
      ),
    );
  }
}

class _BookingDetailScreen extends StatefulWidget {
  const _BookingDetailScreen({required this.booking, required this.onRefresh});
  final BookingModel booking;
  final Future<void> Function() onRefresh;
  @override
  State<_BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<_BookingDetailScreen> {
  BookingModel? _currentBooking;
  int _userRating = 0;
  bool _cancelling = false;
  final TtsService _tts = TtsService();

  BookingModel get _effectiveBooking => _currentBooking ?? widget.booking;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
  }

  @override
  void didUpdateWidget(covariant _BookingDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.booking.id != oldWidget.booking.id || widget.booking.status != oldWidget.booking.status) {
      _currentBooking = widget.booking;
    }
  }

  Future<void> _refreshDetail() async {
    await widget.onRefresh();
    try {
      final updated = await context.read<AppState>().bookingRepo.getById(_effectiveBooking.id);
      if (mounted) setState(() => _currentBooking = updated);
    } catch (_) {}
  }

  Future<void> _cancel() async {
    final confirmed = await VoiceConfirmationDialog.show(
      context,
      title: 'முன்பதிவு ரத்து செய்யவா? / Cancel Booking?',
      message: 'இந்த முன்பதிவை ரத்து செய்ய விரும்புகிறீர்களா?',
      actionLabel: 'ரத்து செய் / CANCEL',
    );
    if (confirmed != true) return;

    final repo = context.read<AppState>().bookingRepo;
    final nav = Navigator.of(context);
    setState(() => _cancelling = true);
    try {
      await repo.cancel(_effectiveBooking.id);
      await widget.onRefresh();
      if (mounted) nav.pop();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _effectiveBooking;
    final isCompleted = b.status == 'completed';
    final isCancellable = b.status == 'pending' || b.status == 'confirmed';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'முன்பதிவு விவரம் / Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingStatusCard(booking: b),
            const SizedBox(height: 12),

            // Live Status Progress Tracker
            BookingWorkflowTracker(
              booking: b,
              isOwner: false,
              onStatusUpdated: _refreshDetail,
            ),
            const SizedBox(height: 14),

            // Machine Owner Contact Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'இயந்திர உரிமையாளர் / Machine Owner',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.owner?.name.isNotEmpty == true ? b.owner!.name : 'உரிமையாளர் / Owner',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          b.owner?.phone.isNotEmpty == true ? b.owner!.phone : '+91 98765 43210',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.call_rounded, color: AppColors.success, size: 24),
                      onPressed: () {
                        _tts.speak('உரிமையாளரை அழைக்கிறோம்');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (isCompleted) ...[
              const Text('மதிப்பிடுங்கள் / Rate Experience',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Center(
                child: StarRatingWidget(
                  rating: _userRating.toDouble(),
                  starSize: 48,
                  interactive: true,
                  onRated: (r) {
                    setState(() => _userRating = r);
                    _tts.speak('$r நட்சத்திரம்');
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_userRating > 0)
                ElevatedButton(
                  onPressed: () {
                    _tts.speak('நன்றி!');
                    Navigator.pop(context);
                  },
                  child: const Text('மதிப்பீடு சமர்ப்பி / Submit Rating'),
                ),
            ],

            const SizedBox(height: 20),

            if (isCancellable)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                ),
                onPressed: _cancelling ? null : _cancel,
                icon: _cancelling
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.cancel_rounded),
                label: const Text('ரத்து செய் / Cancel Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    );
  }
}
