import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import 'payment_providers.dart';

/// Shown on Booking Details once a booking is completed. Only the provider
/// gets an action here (recording cash received) — this mirrors who's
/// physically present to collect payment in an in-home service model; the
/// customer sees a read-only status.
class PaymentSection extends ConsumerStatefulWidget {
  const PaymentSection({required this.bookingId, required this.isProviderView, super.key});

  final String bookingId;
  final bool isProviderView;

  @override
  ConsumerState<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<PaymentSection> {
  bool _recording = false;

  Future<void> _recordCash() async {
    setState(() => _recording = true);
    try {
      await ref.read(paymentRepositoryProvider).recordCashPayment(widget.bookingId);
      ref.invalidate(paymentForBookingProvider(widget.bookingId));
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(paymentForBookingProvider(widget.bookingId));

    return paymentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (payment) {
        if (payment != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency} '
                    '(${payment.paymentProvider}) — ${payment.status}',
                  ),
                  if (widget.isProviderView)
                    Text('You receive: ${payment.providerAmount.toStringAsFixed(0)} ${payment.currency}'),
                ],
              ),
            ),
          );
        }

        if (!widget.isProviderView) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Payment pending.'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _recording ? null : _recordCash,
                  child: _recording
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mark as paid (cash)'),
                ),
                const SizedBox(height: 4),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Digital payment (coming soon)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
