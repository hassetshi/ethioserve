import 'booking.dart';
import 'booking_status.dart';

abstract class BookingRepository {
  /// Creates a booking with status 'requested'. `customer_id` is always the
  /// caller (RLS enforces this too — see bookings_insert_customer).
  Future<Booking> createBooking({
    required String providerId,
    required String serviceId,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String address,
    double? latitude,
    double? longitude,
    String? description,
  });

  Future<List<Booking>> getMyBookingsAsCustomer();

  Future<List<Booking>> getMyBookingsAsProvider(String providerId);

  Future<Booking> getBookingDetail(String bookingId);

  /// Live updates via Supabase Realtime, for the Booking Tracking screen.
  Stream<Booking> watchBooking(String bookingId);

  /// Attempts a status transition. The server (trigger) is the actual
  /// authority on whether this is legal for the caller's role and the
  /// booking's current status — this just surfaces whatever it decides.
  Future<void> updateStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? cancellationReason,
    double? finalPrice,
  });
}
