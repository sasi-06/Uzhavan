import 'package:flutter/material.dart';
import '../../core/models/machine_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/machine_icons.dart';
import '../booking/booking_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key, required this.machines, required this.type});

  final List<MachineModel> machines;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${type[0].toUpperCase()}${type.substring(1)}s nearby')),
      body: machines.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(machineIcon(type), size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No machines found nearby', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: machines.length,
              itemBuilder: (context, i) {
                final m = machines[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(machineIcon(m.type), color: AppColors.primary, size: 32),
                    ),
                    title: Text('Brand: ${m.model ?? m.type}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${m.displayPrice}', style: const TextStyle(fontSize: 16)),
                        Text(
                          '${m.distanceKm?.toStringAsFixed(1) ?? '?'} km away',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        if (m.village != null)
                          Text('Location: ${m.village}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 32),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BookingScreen(machine: m)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
