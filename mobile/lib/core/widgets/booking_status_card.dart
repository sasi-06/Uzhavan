import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';
import '../utils/machine_icons.dart';
import 'package:intl/intl.dart';

class BookingStatusCard extends StatelessWidget {
  const BookingStatusCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showRenterName = false,
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final bool showRenterName;

  static const Map<String, _StatusStyle> _styles = {
    'pending':     _StatusStyle(AppColors.bookingPending,   AppColors.pendingIcon,   Icons.hourglass_top_rounded,   'Pending'),
    'accepted':    _StatusStyle(Color(0xFFE8F5E9),          Color(0xFF2E7D32),        Icons.thumb_up_rounded,        'Accepted ✅'),
    'confirmed':   _StatusStyle(AppColors.bookingConfirmed, AppColors.confirmedIcon, Icons.check_circle_rounded,    'Confirmed'),
    'in_progress': _StatusStyle(Color(0xFFE3F2FD),          Color(0xFF1565C0),        Icons.agriculture_rounded,     'In Progress'),
    'completed':   _StatusStyle(AppColors.bookingCompleted, AppColors.completedIcon, Icons.task_alt_rounded,        'Completed'),
    'cancelled':   _StatusStyle(AppColors.bookingCancelled, AppColors.cancelledIcon, Icons.cancel_rounded,          'Cancelled'),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[booking.status] ?? _styles['pending']!;
    final df    = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.iconColor.withValues(alpha: 0.22), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon badge
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: style.iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(style.icon, color: style.iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(machineIcon(booking.machineType ?? 'tractor'),
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          booking.machineType?.toUpperCase() ?? 'MACHINE',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: style.iconColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: style.iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${df.format(booking.startDate)} – ${df.format(booking.endDate)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (showRenterName && booking.renter != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        booking.renter!.name.isNotEmpty ? booking.renter!.name : booking.renter!.phone,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle(this.bg, this.iconColor, this.icon, this.label);
  final Color bg;
  final Color iconColor;
  final IconData icon;
  final String label;
}
