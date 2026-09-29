import 'package:flutter/material.dart';
import '../services/diesel_audit_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class DieselAuditDialog extends StatefulWidget {
  const DieselAuditDialog({
    super.key,
    required this.bookingId,
    this.machineTitle = 'டிராக்டர் / Tractor',
    this.initialHp = 45,
    this.initialHours = 3.0,
    this.initialImplement = FarmImplementType.rotavator,
    this.initialSoil = SoilCondition.redLoam,
  });

  final String bookingId;
  final String machineTitle;
  final int initialHp;
  final double initialHours;
  final FarmImplementType initialImplement;
  final SoilCondition initialSoil;

  static Future<void> show(
    BuildContext context, {
    required String bookingId,
    String machineTitle = 'டிராக்டர் / Tractor',
    int initialHp = 45,
    double initialHours = 3.0,
    FarmImplementType initialImplement = FarmImplementType.rotavator,
    SoilCondition initialSoil = SoilCondition.redLoam,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DieselAuditDialog(
        bookingId: bookingId,
        machineTitle: machineTitle,
        initialHp: initialHp,
        initialHours: initialHours,
        initialImplement: initialImplement,
        initialSoil: initialSoil,
      ),
    );
  }

  @override
  State<DieselAuditDialog> createState() => _DieselAuditDialogState();
}

class _DieselAuditDialogState extends State<DieselAuditDialog> {
  late int _hp;
  late double _hours;
  late FarmImplementType _implement;
  late SoilCondition _soil;
  late TextEditingController _litresCtrl;
  final TtsService _tts = TtsService();

  double _actualLitres = 15.0;

  @override
  void initState() {
    super.initState();
    _hp = widget.initialHp;
    _hours = widget.initialHours > 0 ? widget.initialHours : 2.5;
    _implement = widget.initialImplement;
    _soil = widget.initialSoil;

    // Estimate initial default actual litres near expected
    final initialExpected = _hp * _implement.loadFactor * _soil.resistanceFactor * _hours;
    _actualLitres = double.parse(initialExpected.toStringAsFixed(1));
    _litresCtrl = TextEditingController(text: _actualLitres.toString());
  }

  @override
  void dispose() {
    _litresCtrl.dispose();
    super.dispose();
  }

  DieselAuditResult get _result {
    return DieselAuditService.instance.auditConsumption(
      horsepower: _hp,
      workingHours: _hours,
      implement: _implement,
      soil: _soil,
      actualLitres: _actualLitres,
    );
  }

  void _speakAudit() {
    final res = _result;
    _tts.setLanguage('ta-IN');
    String msg;
    if (res.status == DieselAuditStatus.normal) {
      msg = 'டீசல் நுகர்வு இயல்பாக உள்ளது. எதிர்பார்க்கப்பட்ட அளவு ${res.expectedLitres} லிட்டர். ஓட்டுநர் கூறிய அளவு ${res.actualLitres} லிட்டர்.';
    } else {
      msg = 'எச்சரிக்கை! எதிர்பார்க்கப்பட்ட அளவை விட ${res.varianceLitres} லிட்டர் கூடுதல் டீசல். கூடுதல் இழப்பு சுமார் ரூபாய் ${res.financialVariance.toStringAsFixed(0)}.';
    }
    _tts.speak(msg);
  }

  @override
  Widget build(BuildContext context) {
    final res = _result;
    final isHigh = res.status == DieselAuditStatus.highAlert;
    final isMod = res.status == DieselAuditStatus.moderate;

    final statusColor = isHigh
        ? AppColors.error
        : (isMod ? const Color(0xFFD97706) : AppColors.success);

    final statusBg = isHigh
        ? AppColors.error.withValues(alpha: 0.12)
        : (isMod ? const Color(0xFFFFFBEB) : AppColors.success.withValues(alpha: 0.12));

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppColors.ownerAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'டீசல் கணக்காய்வு / Fuel Auditor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.machineTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _speakAudit,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.ownerAccent,
                    size: 24,
                  ),
                  tooltip: 'குரல் விளக்கம் / Listen',
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Interactive Parameter Selectors ───────────────────
            // 1. Implement & Soil Pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'கருவி / Implement',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<FarmImplementType>(
                            isExpanded: true,
                            value: _implement,
                            items: FarmImplementType.values.map((imp) {
                              return DropdownMenuItem(
                                value: imp,
                                child: Text(
                                  imp.labelTa.split('(').first.trim(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _implement = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'மண் நிலை / Soil Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SoilCondition>(
                            isExpanded: true,
                            value: _soil,
                            items: SoilCondition.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.labelTa.split('(').first.trim(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _soil = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Working Hours & Horsepower Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'வேலை நேரம் / Hours',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_hours > 0.5) setState(() => _hours -= 0.5);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '${_hours.toStringAsFixed(1)} மணி',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _hours += 0.5),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'குதிரைத்திறன் / Engine HP',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_hp > 25) setState(() => _hp -= 5);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_hp HP',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ownerAccent),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_hp < 110) setState(() => _hp += 5);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Driver Reported Fuel Input ────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, color: Color(0xFF16A34A), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ஓட்டுநர் கூறிய டீசல் அளவு',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        Text(
                          'Driver reported fuel used',
                          style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _litresCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        suffixText: 'L',
                        suffixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF86EFAC))),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          setState(() => _actualLitres = parsed);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Audit Verdict Card ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHigh ? Icons.warning_amber_rounded : (isMod ? Icons.info_outline_rounded : Icons.check_circle_rounded),
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHigh
                            ? 'அசாதாரண டீசல் நுகர்வு / High Fuel Alert!'
                            : (isMod ? 'கவனிக்கத்தக்க வேறுபாடு / Moderate Variance' : 'சரியான நுகர்வு / Normal Consumption'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('எதிர்பார்த்த அளவு (Expected)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${res.expectedLitres} L',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                          ),
                          Text(
                            'வரம்பு: ${res.minSafeLitres} – ${res.maxSafeLitres} L',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.black12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('வித்தியாசம் (Variance)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            '${res.varianceLitres >= 0 ? "+" : ""}${res.varianceLitres} L (${res.variancePercent}%)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                            ),
                          ),
                          if (res.financialVariance > 0)
                            Text(
                              'மதிப்பு: ~₹${res.financialVariance.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      res.adviceTa,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                _speakAudit();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('டீசல் கணக்காய்வு சேமிக்கப்பட்டது: ${res.varianceLitres}L வேறுபாடு'),
                    backgroundColor: AppColors.ownerAccent,
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'சரிபார்த்தேன் / Confirm & Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
