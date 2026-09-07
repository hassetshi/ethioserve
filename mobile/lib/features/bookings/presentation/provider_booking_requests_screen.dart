import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../domain/booking.dart';
import 'booking_providers.dart';
import 'booking_status_chip.dart';

class ProviderBookingRequestsScreen extends ConsumerWidget {
  const ProviderBookingRequestsScreen({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final bookingsAsync = ref.watch(myProviderBookingsProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(child: Text('No booking requests yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final Booking booking = bookings[index];
              return ListTile(
                title: Text(booking.serviceName(languageCode)),
                subtitle: Text(
                  '${booking.customerPhone ?? 'Customer'} • ${booking.scheduledDate} ${booking.scheduledTime.substring(0, 5)}',
                ),
                trailing: BookingStatusChip(status: booking.status),
                onTap: () => context.push('/bookings/${booking.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
