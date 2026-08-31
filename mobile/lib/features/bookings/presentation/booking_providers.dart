import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_booking_repository.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return SupabaseBookingRepository(Supabase.instance.client);
});

final myCustomerBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return ref.watch(bookingRepositoryProvider).getMyBookingsAsCustomer();
});

final myProviderBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, String>((ref, providerId) {
  return ref.watch(bookingRepositoryProvider).getMyBookingsAsProvider(providerId);
});

/// Live-updating booking, for the Booking Tracking / Details screen.
final bookingStreamProvider =
    StreamProvider.autoDispose.family<Booking, String>((ref, bookingId) {
  return ref.watch(bookingRepositoryProvider).watchBooking(bookingId);
});
