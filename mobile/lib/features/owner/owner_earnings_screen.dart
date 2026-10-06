import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/diesel_audit_dialog.dart';

class OwnerEarningsScreen extends StatefulWidget {
  const OwnerEarningsScreen({super.key});
  @override
  State<OwnerEarningsScreen> createState() => _OwnerEarningsScreenState();
}

class _OwnerEarningsScreenState extends State<OwnerEarningsScreen>
    with SingleTickerProviderStateMixin {
  final TtsService _tts = TtsService();
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  // Placeholder data — replace with real backend call
  final double _totalThisMonth = 12500;
  final List<double> _weeklyEarnings = [2200, 3100, 4500, 2700];
  final List<String> _weekLabels = ['வாரம் 1', 'வாரம் 2', 'வாரம் 3', 'வாரம் 4'];

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    _barCtrl.forward();
  }

  @override
  void dispose() { _barCtrl.dispose(); super.dispose(); }

  void _speakTotal() {
    _tts.setLanguage('ta-IN');
    _tts.speak('இந்த மாதம் மொத்தம் ₹${_totalThisMonth.toStringAsFixed(0)} வருமானம்');
  }

  double get _maxWeek => _weeklyEarnings.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('வருமானம்', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // ── Total Earnings Card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ownerAccent, Color(0xFF0D47A1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.ownerAccent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(children: [
                const Text('இந்த மாதம் மொத்தம்', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('₹${_totalThisMonth.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _speakTotal,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Weekly Bar Chart ─────────────────────────────
            const Text('வாரம் வாரம் வருமானம்', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),

            SizedBox(
              height: 180,
              child: AnimatedBuilder(
                animation: _barAnim,
                builder: (_, __) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(_weeklyEarnings.length, (i) {
                    final ratio = (_weeklyEarnings[i] / _maxWeek) * _barAnim.value;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('₹${_weeklyEarnings[i].toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ownerAccent)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              height: 140 * ratio,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.ownerAccent.withValues(alpha: 0.7), AppColors.ownerAccent],
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                ),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_weekLabels[i], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Diesel Audit Summary Card ────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_gas_station_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'டீசல் கண்காணிப்பு / Fuel Audit',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                            ),
                            Text(
                              'திருட்டு & அதிக நுகர்வு தடுப்பு',
                              style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF166534),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF86EFAC))),
                        ),
                        onPressed: () {
                          DieselAuditDialog.show(
                            context,
                            bookingId: 'quick_calc',
                            machineTitle: 'மஹிந்திரா 575 DI (45 HP)',
                            initialHp: 45,
                            initialHours: 3.0,
                          );
                        },
                        icon: const Icon(Icons.calculate_rounded, size: 16),
                        label: const Text('கணக்கிடு', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 18, color: Color(0xFFBBF7D0)),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('மாத டீசல் நுகர்வு', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                          SizedBox(height: 2),
                          Text('148 L', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                        ],
                      ),
                      Column(
                        children: [
                          Text('பாதுகாக்கப்பட்ட தொகை', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                          SizedBox(height: 2),
                          Text('~₹1,240', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Payout Button ────────────────────────────────
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                _tts.setLanguage('ta-IN');
                _tts.speak('பணம் எடுக்கிறோம்');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payout initiated!')),
                );
              },
              icon: const Icon(Icons.account_balance_rounded, size: 24),
              label: const Text('பணம் எடு / Withdraw', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }
}
