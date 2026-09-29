import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/machine_model.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/machine_type_tile.dart';
import '../../core/utils/machine_icons.dart';
import 'add_machine_flow_screen.dart';

class OwnerMachinesScreen extends StatefulWidget {
  const OwnerMachinesScreen({super.key});
  @override
  State<OwnerMachinesScreen> createState() => _OwnerMachinesScreenState();
}

class _OwnerMachinesScreenState extends State<OwnerMachinesScreen> {
  List<MachineModel> _machines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await context.read<AppState>().machineRepo.getMyMachines();
      setState(() => _machines = list);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) => s == 'active' ? AppColors.success : AppColors.warning;
  IconData _statusIcon(String s) => s == 'active' ? Icons.check_circle_rounded : Icons.build_rounded;
  String _statusLabel(String s) => s == 'active' ? 'Active' : 'Maintenance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('என் எந்திரங்கள்',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('மீண்டும்')),
                ]))
              : _machines.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.agriculture_rounded, size: 90, color: AppColors.divider),
                      const SizedBox(height: 16),
                      const Text('எந்திரங்கள் இல்லை', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _openAddFlow(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ownerAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('எந்திரம் சேர்', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _machines.length,
                        itemBuilder: (_, i) {
                          final m = _machines[i];
                          return _MachineGridCard(
                            machine: m,
                            statusColor: _statusColor(m.status),
                            statusIcon: _statusIcon(m.status),
                            statusLabel: _statusLabel(m.status),
                            onRefresh: _load,
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFlow,
        backgroundColor: AppColors.ownerAccent,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text('எந்திரம் சேர்', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openAddFlow() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMachineFlowScreen()));
    if (result == true) {
      _load();
    }
  }
}

class _MachineGridCard extends StatelessWidget {
  const _MachineGridCard({
    required this.machine,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.onRefresh,
  });
  final MachineModel machine;
  final Color statusColor;
  final IconData statusIcon;
  final String statusLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Photo
        ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: machine.photos.isNotEmpty
                ? Image.network(machine.photos.first, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ImgPlaceholder(type: machine.type))
                : _ImgPlaceholder(type: machine.type),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(machine.model ?? machine.type,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            // Status pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                  ]),
                ),
                if (machine.isOverdueForServicing) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Overdue',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(machine.displayPrice, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700)),
            
            if (machine.isOverdueForServicing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ownerAccent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    // Log service date
                    final dateStr = DateTime.now().toIso8601String().split('T').first;
                    await FirebaseFirestore.instance
                        .collection('machines')
                        .doc(machine.id)
                        .update({'lastServiceDate': dateStr});
                    onRefresh();
                  },
                  child: const Text(
                    'Log Service',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder({required this.type});
  final String type;
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary.withValues(alpha: 0.08),
    child: Center(child: Icon(machineIcon(type), size: 48, color: AppColors.primary.withValues(alpha: 0.4))),
  );
}

// ── 4-Step Add Machine Flow ────────────────────────────────────────────────

class OwnerAddMachineFlow extends StatefulWidget {
  const OwnerAddMachineFlow({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OwnerAddMachineFlow> createState() => _OwnerAddMachineFlowState();
}

class _OwnerAddMachineFlowState extends State<OwnerAddMachineFlow> {
  int _step = 0;
  String? _type;
  double _price = 500;
  bool _perAcre = true;
  bool _operatorIncluded = false;
  final Set<DateTime> _blockedDates = {};
  bool _loading = false;
  String? _error;

  static const _types = ['tractor', 'harvester', 'plough', 'seeder', 'sprayer'];

  bool get _canNext {
    if (_step == 0) return _type != null;
    return true;
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = context.read<AppState>();
      await s.machineRepo.create(
        type: _type!,
        pricePerHour: _perAcre ? null : _price,
        pricePerAcre: _perAcre ? _price : null,
        operatorIncluded: _operatorIncluded,
        latitude: s.latitude,
        longitude: s.longitude,
      );
      widget.onDone();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().user?.preferredLanguage ?? 'ta';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('படி ${_step + 1} / 4', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        LinearProgressIndicator(value: (_step + 1) / 4, color: AppColors.ownerAccent, backgroundColor: AppColors.divider, minHeight: 6),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildStep(lang),
        )),
        if (_error != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(_error!, style: const TextStyle(color: AppColors.error))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Row(children: [
            if (_step > 0) ...[
              Expanded(child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => setState(() => _step--),
                child: const Text('முந்தைய'),
              )),
              const SizedBox(width: 12),
            ],
            Expanded(flex: 2, child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: (!_canNext || _loading) ? null : () {
                if (_step < 3) setState(() => _step++);
                else _submit();
              },
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_step < 3 ? 'அடுத்து →' : 'சேமி ✓', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep(String lang) {
    switch (_step) {
      case 0:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('எந்திர வகை தேர்ந்தெடுக்க', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12),
            itemCount: _types.length,
            itemBuilder: (_, i) => MachineTypeTile(
              type: _types[i], lang: lang,
              selected: _type == _types[i],
              onTap: () => setState(() => _type = _types[i]),
              size: 100,
            ),
          )),
        ]);
      case 1:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('புகைப்படம்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          Expanded(child: Center(child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider, width: 2, style: BorderStyle.values[1]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.camera_alt_rounded, size: 80, color: AppColors.ownerAccent.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              const Text('எந்திரத்தை சட்டத்தில் வை', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.ownerAccent),
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('புகைப்படம் எடு', style: TextStyle(fontSize: 16)),
              ),
            ]),
          ))),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('விலை நிர்ணயம்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          // Per Acre / Per Hour toggle
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _perAcre = true),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _perAcre ? AppColors.ownerAccent : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _perAcre ? AppColors.ownerAccent : AppColors.divider),
                ),
                child: Column(children: [
                  Icon(Icons.crop_rounded, size: 32, color: _perAcre ? Colors.white : AppColors.ownerAccent),
                  const SizedBox(height: 6),
                  Text('ஏக்கருக்கு', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _perAcre ? Colors.white : AppColors.textPrimary)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _perAcre = false),
              child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: !_perAcre ? AppColors.ownerAccent : AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: !_perAcre ? AppColors.ownerAccent : AppColors.divider),
                ),
                child: Column(children: [
                  Icon(Icons.access_time_rounded, size: 32, color: !_perAcre ? Colors.white : AppColors.ownerAccent),
                  const SizedBox(height: 6),
                  Text('மணிக்கு', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: !_perAcre ? Colors.white : AppColors.textPrimary)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 32),
          Center(child: Text('₹${_price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: AppColors.ownerAccent))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _BigOBtn(icon: Icons.remove_rounded, onTap: _price > 100 ? () => setState(() => _price -= 100) : null),
            const SizedBox(width: 24),
            _BigOBtn(icon: Icons.add_rounded, onTap: () => setState(() => _price += 100), color: AppColors.ownerAccent),
          ]),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _operatorIncluded,
            onChanged: (v) => setState(() => _operatorIncluded = v),
            title: const Row(children: [
              Icon(Icons.engineering_rounded, color: AppColors.ownerAccent),
              SizedBox(width: 10),
              Text('உழைப்பாளர் உட்பட', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]);
      case 3:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('கிடைக்கும் நாட்கள்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('சிவப்பு = முடக்கப்பட்டது · பச்சை = கிடைக்கும்',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _AvailabilityCalendar(blocked: _blockedDates, onToggle: (d) {
            setState(() {
              if (_blockedDates.contains(d)) _blockedDates.remove(d);
              else _blockedDates.add(d);
            });
          }),
        ]);
      default: return const SizedBox();
    }
  }
}

class _BigOBtn extends StatelessWidget {
  const _BigOBtn({required this.icon, this.onTap, this.color});
  final IconData icon; final VoidCallback? onTap; final Color? color;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle, color: onTap != null ? (color ?? AppColors.divider) : AppColors.divider.withValues(alpha: 0.4)),
      child: Icon(icon, size: 36, color: Colors.white),
    ),
  );
}

class _AvailabilityCalendar extends StatefulWidget {
  const _AvailabilityCalendar({required this.blocked, required this.onToggle});
  final Set<DateTime> blocked;
  final ValueChanged<DateTime> onToggle;
  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  late DateTime _month;
  @override
  void initState() { super.initState(); _month = DateTime(DateTime.now().year, DateTime.now().month); }

  bool _isBlocked(DateTime d) => widget.blocked.any((b) => b.year == d.year && b.month == d.month && b.day == d.day);

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstDay = DateTime(_month.year, _month.month, 1).weekday;

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded, size: 32), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
        Text('${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][_month.month - 1]} ${_month.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        IconButton(icon: const Icon(Icons.chevron_right_rounded, size: 32), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
      ]),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
        itemCount: daysInMonth + firstDay - 1,
        itemBuilder: (_, i) {
          final dayNum = i - firstDay + 2;
          if (dayNum < 1) return const SizedBox();
          final date = DateTime(_month.year, _month.month, dayNum);
          final blocked = _isBlocked(date);
          return GestureDetector(
            onTap: () => widget.onToggle(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: blocked ? AppColors.error.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: blocked ? AppColors.error.withValues(alpha: 0.5) : AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Center(child: Text('$dayNum', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: blocked ? AppColors.error : AppColors.success))),
            ),
          );
        },
      ),
    ]);
  }
}
