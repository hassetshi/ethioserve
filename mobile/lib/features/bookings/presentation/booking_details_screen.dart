import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/locale_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../providers/presentation/provider_providers.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_providers.dart';
import 'booking_status_chip.dart';

class BookingDetailsScreen extends ConsumerWidget {
  const BookingDetailsScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingStreamProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Something went wrong. Please try again.')),
        data: (booking) => _BookingDetailsBody(booking: booking),
      ),
    );
  }
}

class _BookingDetailsBody extends ConsumerWidget {
  const _BookingDetailsBody({required this.booking});

  final Booking booking;

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    BookingStatus status, {
    String? cancellationReason,
    double? finalPrice,
  }) async {
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(
            booking.id,
            status,
            cancellationReason: cancellationReason,
            finalPrice: finalPrice,
          );
    } on ValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  Future<String?> _promptForReason(BuildContext context, String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<double?> _promptForFinalPrice(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as completed'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Final price (ETB, optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(double.tryParse(controller.text.trim())),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final myProviderId = ref.watch(myProviderIdProvider).valueOrNull;

    final isCustomerView = currentUser != null && booking.customerId == currentUser.id;
    final isProviderView = myProviderId != null && booking.providerId == myProviderId;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.serviceName(languageCode),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              BookingStatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          if (booking.providerBusinessName != null)
            Text('Provider: ${booking.providerBusinessName}'),
          if (booking.customerPhone != null) Text('Customer: ${booking.customerPhone}'),
          const SizedBox(height: 8),
          Text('${booking.scheduledDate} at ${booking.scheduledTime.substring(0, 5)}'),
          const SizedBox(height: 4),
          Text(booking.address),
          if (booking.description != null) ...[
            const SizedBox(height: 12),
            Text(booking.description!),
          ],
          if (booking.finalPrice != null) ...[
            const SizedBox(height: 12),
            Text('Final price: ${booking.finalPrice!.toStringAsFixed(0)} ETB'),
          ],
          if (booking.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Text('Reason: ${booking.cancellationReason}'),
          ],
          const SizedBox(height: 24),
          if (isProviderView) ..._providerActions(context, ref),
          if (isCustomerView && !booking.status.isTerminal) _cancelAction(context, ref),
        ],
      ),
    );
  }

  List<Widget> _providerActions(BuildContext context, WidgetRef ref) {
    switch (booking.status) {
      case BookingStatus.requested:
        return [
          FilledButton(
            onPressed: () => _updateStatus(context, ref, BookingStatus.accepted),
            child: const Text('Accept'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final reason = await _promptForReason(context, 'Decline this request?');
              if (reason != null && context.mounted) {
                await _updateStatus(context, ref, BookingStatus.declined,
                    cancellationReason: reason.isEmpty ? null : reason);
              }
            },
            child: const Text('Decline'),
          ),
        ];
      case BookingStatus.accepted:
        return [
          FilledButton(
            onPressed: () => _updateStatus(context, ref, BookingStatus.onTheWay),
            child: const Text("I'm on the way"),
          ),
        ];
      case BookingStatus.onTheWay:
        return [
          FilledButton(
            onPressed: () => _updateStatus(context, ref, BookingStatus.inProgress),
            child: const Text('Start job'),
          ),
        ];
      case BookingStatus.inProgress:
        return [
          FilledButton(
            onPressed: () async {
              final price = await _promptForFinalPrice(context);
              if (context.mounted) {
                await _updateStatus(context, ref, BookingStatus.completed, finalPrice: price);
              }
            },
            child: const Text('Mark completed'),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _cancelAction(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () async {
        final reason = await _promptForReason(context, 'Cancel this booking?');
        if (reason != null && context.mounted) {
          await _updateStatus(context, ref, BookingStatus.cancelled,
              cancellationReason: reason.isEmpty ? null : reason);
        }
      },
      child: const Text('Cancel booking'),
    );
  }
}
