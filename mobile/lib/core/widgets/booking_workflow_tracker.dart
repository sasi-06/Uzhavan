import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../services/tts_service.dart';

class BookingWorkflowTracker extends StatefulWidget {
  const BookingWorkflowTracker({
    super.key,
    required this.booking,
    this.isOwner = false,
    this.onStatusUpdated,
  });

  final BookingModel booking;
  final bool isOwner;
  final Future<void> Function()? onStatusUpdated;

  @override
  State<BookingWorkflowTracker> createState() => _BookingWorkflowTrackerState();
}

class _BookingWorkflowTrackerState extends State<BookingWorkflowTracker> {
  bool _updating = false;
  final TtsService _tts = TtsService();

  static const List<_WorkflowStep> _steps = [
    _WorkflowStep(
      key: 'pending',
      label: 'கோரிக்கை',
      sublabel: 'Requested',
      icon: Icons.hourglass_top_rounded,
      activeColor: AppColors.pendingIcon,
    ),
    _WorkflowStep(
      key: 'accepted',
      label: 'ஏற்கப்பட்டது',
      sublabel: 'Accepted',
      icon: Icons.thumb_up_rounded,
      activeColor: Color(0xFF2E7D32),
    ),
    _WorkflowStep(
      key: 'confirmed',
      label: 'உறுதி',
      sublabel: 'Confirmed',
      icon: Icons.check_circle_rounded,
      activeColor: AppColors.ownerAccent,
    ),
    _WorkflowStep(
      key: 'in_progress',
      label: 'பணியில்',
      sublabel: 'In Progress',
      icon: Icons.agriculture_rounded,
      activeColor: Color(0xFF1565C0),
    ),
    _WorkflowStep(
      key: 'completed',
      label: 'முடிந்தது',
      sublabel: 'Completed',
      icon: Icons.payments_rounded,
      activeColor: Color(0xFF00796B),
    ),
  ];

  int _getStepIndex(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'pending' || s == 'requested' || s == 'new') return 0;
    if (s == 'accepted') return 1;
    if (s == 'confirmed') return 2;
    if (s == 'in_progress' || s == 'picked_up' || s == 'in_use') return 3;
    if (s == 'completed' || s == 'paid') return 4;
    return 0;
  }

  Future<void> _advanceStatus(String nextStatus, String speechMessage) async {
    setState(() => _updating = true);
    try {
      _tts.speak(speechMessage);
      final repo = context.read<AppState>().bookingRepo;
      await repo.updateStatus(widget.booking.id, nextStatus);
      await widget.onStatusUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status update error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.booking.status.toLowerCase().trim();
    if (currentStatus == 'cancelled') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'இந்த முன்பதிவு ரத்து செய்யப்பட்டுள்ளது / Booking Cancelled',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final activeIndex = _getStepIndex(currentStatus);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Title ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.linear_scale_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'முன்பதிவு நிலை / Booking Status Tracker',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _steps[activeIndex].activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _steps[activeIndex].label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _steps[activeIndex].activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Horizontal 4-Step Stepper Bar (Clickable logos for Farmer & Owner) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isDone = index <= activeIndex;
              final isCurrent = index == activeIndex;
              final isClickable = index > activeIndex;

              return Expanded(
                child: Row(
                  children: [
                    // Step Icon & Label Node (Wrapped with InkWell for clickability)
                    Expanded(
                      child: Tooltip(
                        message: isClickable
                            ? 'தட்டவும்: ${step.label} (${step.sublabel}) / Tap to update'
                            : '${step.label} (${step.sublabel})',
                        child: InkWell(
                          onTap: () => _onStepTapped(index),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: isCurrent ? 44 : 38,
                                    height: isCurrent ? 44 : 38,
                                    decoration: BoxDecoration(
                                      color: isDone
                                          ? step.activeColor.withValues(alpha: isCurrent ? 0.16 : 0.10)
                                          : (isClickable
                                              ? step.activeColor.withValues(alpha: 0.08)
                                              : Colors.grey.shade100),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDone
                                            ? step.activeColor
                                            : (isClickable
                                                ? step.activeColor.withValues(alpha: 0.6)
                                                : Colors.grey.shade300),
                                        width: isCurrent ? 2.5 : (isClickable ? 1.8 : 1.5),
                                      ),
                                      boxShadow: isCurrent
                                          ? [
                                              BoxShadow(
                                                color: step.activeColor.withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : (isClickable
                                              ? [
                                                  BoxShadow(
                                                    color: step.activeColor.withValues(alpha: 0.12),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  )
                                                ]
                                              : null),
                                    ),
                                    child: Icon(
                                      step.icon,
                                      size: isCurrent ? 22 : 18,
                                      color: isDone
                                          ? step.activeColor
                                          : (isClickable
                                              ? step.activeColor
                                              : Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isDone
                                        ? FontWeight.w800
                                        : (isClickable ? FontWeight.w700 : FontWeight.w500),
                                    color: isDone
                                        ? step.activeColor
                                        : (isClickable ? step.activeColor : Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Connecting Bar
                    if (index < _steps.length - 1)
                      Container(
                        width: 24,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: index < activeIndex
                              ? _steps[index + 1].activeColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // ── Status Description Banner ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _steps[activeIndex].activeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _steps[activeIndex].activeColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(_steps[activeIndex].icon, size: 18, color: _steps[activeIndex].activeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getStatusDescription(activeIndex),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _steps[activeIndex].activeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Action Controls (Owner OR Farmer) ───────────────────────────
          if (widget.isOwner && _ownerCanAct(activeIndex)) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _updating ? null : () => _onAdvanceClicked(activeIndex),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _steps[activeIndex + 1].activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _updating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_steps[activeIndex + 1].icon, size: 20),
                label: Text(
                  _getOwnerActionText(activeIndex),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (widget.isOwner && activeIndex == 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFF9A825), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'விவசாயி உறுதிப்படுத்த காத்திருக்கிறோம் / Waiting for farmer to confirm',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!widget.isOwner && activeIndex >= 1 && activeIndex < _steps.length - 1) ...[
            // Farmer can update status: confirmed (taken), in_progress (working), completed (done)
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _updating ? null : () => _onStepTapped(activeIndex + 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _steps[activeIndex + 1].activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: _updating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_steps[activeIndex + 1].icon, size: 20),
                label: Text(
                  _getFarmerActionText(activeIndex),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ] else if (!widget.isOwner && activeIndex == 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9C4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFF9A825), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'உரிமையாளர் ஏற்க காத்திருக்கிறது / Waiting for owner to accept',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE65100)),
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

  void _onStepTapped(int index) {
    if (_updating) return;
    final activeIndex = _getStepIndex(widget.booking.status.toLowerCase().trim());
    if (index == activeIndex) {
      _tts.speak(_getStatusDescription(index));
      return;
    }
    if (index < activeIndex) {
      _tts.speak('${_steps[index].label} ஏற்கனவே முடிந்தது');
      return;
    }
    // Advance to this step directly when clicked
    final targetStep = _steps[index];
    final speech = _getSpeech(index, widget.isOwner);
    _advanceStatus(targetStep.key, speech);
  }

  String _getSpeech(int targetIndex, bool isOwner) {
    if (isOwner) {
      switch (targetIndex) {
        case 1:
          return 'கோரிக்கை ஏற்கப்பட்டது. தேதி பூட்டப்பட்டுள்ளது';
        case 2:
          return 'முன்பதிவு உறுதி செய்யப்பட்டது';
        case 3:
          return 'எந்திரம் வயலுக்கு கிளம்பியது. பணியில் உள்ளது';
        case 4:
          return 'பணம் பெறப்பட்டு முன்பதிவு முடிந்தது';
        default:
          return 'நிலை புதுப்பிக்கப்பட்டது';
      }
    } else {
      switch (targetIndex) {
        case 2:
          return 'எந்திரம் எடுக்கப்பட்டது. முன்பதிவு உறுதி செய்யப்பட்டது';
        case 3:
          return 'எந்திரம் பணியில் உள்ளது. வேலை தொடங்கப்பட்டது';
        case 4:
          return 'வேலை நிறைவுற்றது. முன்பதிவு முடிந்தது';
        default:
          return 'நிலை புதுப்பிக்கப்பட்டது';
      }
    }
  }

  String _getFarmerActionText(int currentIndex) {
    switch (currentIndex) {
      case 1:
        return '🚜 எந்திரம் எடுக்கப்பட்டது / Confirm & Take Machine';
      case 2:
        return '🌾 பணியைத் தொடங்கு / Start Work';
      case 3:
        return '✅ பணி முடிந்தது / Complete Work';
      default:
        return 'அடுத்து / Next Stage';
    }
  }

  String _getStatusDescription(int index) {
    switch (index) {
      case 0:
        return 'காத்திருக்கிறது: உரிமையாளர் கோரிக்கையை மதிப்பாய்வு செய்கிறார் / Waiting for owner to accept';
      case 1:
        return 'ஏற்கப்பட்டது ✅: உரிமையாளர் கோரிக்கையை ஏற்றுக்கொண்டார். தேதி பூட்டப்பட்டுள்ளது / Owner accepted — dates are locked';
      case 2:
        return 'உறுதி செய்யப்பட்டது: விவசாயி உறுதிப்படுத்தினார். எந்திரம் வர தயார் / Farmer confirmed — machine en route';
      case 3:
        return 'பணியில் உள்ளது: எந்திரம் வயலில் வேலை செய்கிறது / Machine is working in the field';
      case 4:
        return 'பணம் முடிந்தது: வாடகைத் தொகை செலுத்தப்பட்டு முன்பதிவு நிறைவடைந்தது / Payment released, booking complete';
      default:
        return '';
    }
  }

  bool _ownerCanAct(int index) {
    // Owner acts at: pending(0), confirmed(2), in_progress(3)
    return index == 0 || index == 2 || index == 3;
  }

  String _getOwnerActionText(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return '✔️ கோரிக்கை ஏற்கவும் / Accept Request';
      case 2:
        return '🚜 எந்திரம் கிளம்பியது / Mark In Progress';
      case 3:
        return '💰 பணம் பெறப்பட்டது / Mark Completed';
      default:
        return 'அடுத்து / Next Stage';
    }
  }

  void _onAdvanceClicked(int currentIndex) {
    switch (currentIndex) {
      case 0:
        setState(() => _updating = true);
        context.read<AppState>().bookingRepo.ownerConfirm(widget.booking.id).then((_) async {
          _tts.speak('கோரிக்கை ஏற்கப்பட்டது. தேதி பூட்டப்பட்டுள்ளது');
          await widget.onStatusUpdated?.call();
          if (mounted) setState(() => _updating = false);
        }).catchError((_) {
          if (mounted) setState(() => _updating = false);
        });
        break;
      case 2:
        _advanceStatus('in_progress', 'எந்திரம் வயலுக்கு கிளம்பியது');
        break;
      case 3:
        _advanceStatus('completed', 'பணம் பெறப்பட்டு முன்பதிவு முடிந்தது');
        break;
    }
  }
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.key,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.activeColor,
  });

  final String key;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color activeColor;
}
