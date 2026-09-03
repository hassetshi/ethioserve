import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import 'payment_providers.dart';

/// Shown on Booking Details once a booking is completed. The provider can
/// record cash collected in person; the customer can pay by card via
/// Stripe — each side only gets the action that's actually theirs to take.
class PaymentSection extends ConsumerStatefulWidget {
  const PaymentSection({
    required this.bookingId,
    required this.isProviderView,
    super.key,
  });

  final String bookingId;
  final bool isProviderView;

  @override
  ConsumerState<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends ConsumerState<PaymentSection> {
  bool _busy = false;

  Future<void> _recordCash() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .recordCashPayment(widget.bookingId);
      ref.invalidate(paymentForBookingProvider(widget.bookingId));
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payWithCard() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(paymentRepositoryProvider)
          .initializeDigitalPayment(widget.bookingId);
      ref.invalidate(paymentForBookingProvider(widget.bookingId));
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _busyButton({required VoidCallback onPressed, required String label}) {
    return FilledButton(
      onPressed: _busy ? null : onPressed,
      child: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
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
                  Text(
                    'Payment',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency} '
                    '(${payment.paymentProvider}) — ${payment.status}',
                  ),
                  if (widget.isProviderView)
                    Text(
                      'You receive: ${payment.providerAmount.toStringAsFixed(0)} ${payment.currency}',
                    ),
                ],
              ),
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
                if (widget.isProviderView)
                  _busyButton(
                    onPressed: _recordCash,
                    label: 'Mark as paid (cash)',
                  )
                else
                  _busyButton(onPressed: _payWithCard, label: 'Pay with card'),
              ],
            ),
          ),
        );
      },
    );
  }
}
