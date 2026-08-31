import 'package:ethioserve/features/bookings/domain/booking.dart';
import 'package:ethioserve/features/bookings/domain/booking_repository.dart';
import 'package:ethioserve/features/bookings/domain/booking_status.dart';

Booking _testBooking({BookingStatus status = BookingStatus.requested}) => Booking(
      id: 'booking-1',
      customerId: 'customer-1',
      providerId: 'provider-1',
      serviceId: 'service-1',
      scheduledDate: '2026-09-05',
      scheduledTime: '10:00:00',
      address: 'Bole, Addis Ababa',
      status: status,
      createdAt: DateTime(2026, 8, 31),
      providerBusinessName: 'Addis Plumbing Experts',
      serviceNameEn: 'Pipe Repair',
      serviceNameAm: 'የቧንቧ ጥገና',
      customerPhone: '+251912345678',
    );

class FakeBookingRepository implements BookingRepository {
  BookingStatus currentStatus = BookingStatus.requested;

  @override
  Future<Booking> createBooking({
    required String providerId,
    required String serviceId,
    required DateTime scheduledDate,
    required String scheduledTime,
    required String address,
    double? latitude,
    double? longitude,
    String? description,
  }) async =>
      _testBooking();

  @override
  Future<List<Booking>> getMyBookingsAsCustomer() async => [_testBooking(status: currentStatus)];

  @override
  Future<List<Booking>> getMyBookingsAsProvider(String providerId) async =>
      [_testBooking(status: currentStatus)];

  @override
  Future<Booking> getBookingDetail(String bookingId) async => _testBooking(status: currentStatus);

  @override
  Stream<Booking> watchBooking(String bookingId) => Stream.value(_testBooking(status: currentStatus));

  @override
  Future<void> updateStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? cancellationReason,
    double? finalPrice,
  }) async {
    currentStatus = newStatus;
  }
}
