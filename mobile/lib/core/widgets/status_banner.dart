import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusType { success, pending, error, info }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.type,
    required this.icon,
    this.message,
  });

  final StatusType type;
  final IconData icon;
  final String? message;

  Color get _color => switch (type) {
        StatusType.success => AppColors.primary,
        StatusType.pending => AppColors.pending,
        StatusType.error => AppColors.error,
        StatusType.info => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _color),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: TextStyle(fontSize: 16, color: _color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
