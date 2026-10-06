import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/status_banner.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  final String bookingId;
  final double amount;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  String? _error;
  bool _done = false;
  String? _message;

  Future<void> _pay(String mode) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<AppState>().bookingRepo.initiatePayment(
            bookingId: widget.bookingId,
            mode: mode,
          );
      setState(() {
        _done = true;
        _message = res['message'] as String? ?? 'Payment initiated';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_done)
                        StatusBanner(
                          type: StatusType.success,
                          icon: Icons.check_circle_rounded,
                          message: _message,
                        )
                      else ...[
                        Text('₹${widget.amount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : () => _pay('upi'),
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Pay via UPI'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loading ? null : () => _pay('cash'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                          icon: const Icon(Icons.money),
                          label: const Text('Cash on Pickup'),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 16)),
                      ],
                      const Spacer(),
                      if (_done)
                        ElevatedButton(
                          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                          child: const Text('Done'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
