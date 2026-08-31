import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/booking.dart';
import 'booking_providers.dart';

class BookingRequestController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<Booking?> submit({
    required String providerId,
    required String serviceId,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String address,
    String? description,
  }) async {
    state = const AsyncLoading();
    Booking? booking;
    state = await AsyncValue.guard(() async {
      booking = await ref.read(bookingRepositoryProvider).createBooking(
            providerId: providerId,
            serviceId: serviceId,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            address: address,
            description: description,
          );
    });
    return state.hasError ? null : booking;
  }
}

final bookingRequestControllerProvider =
    AsyncNotifierProvider<BookingRequestController, void>(
  BookingRequestController.new,
);
