import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/booking.dart';
import '../domain/booking_repository.dart';
import '../domain/booking_status.dart';

const _detailSelect =
    '*, provider_profiles(business_name, user_id), services(name_en, name_am), users!bookings_customer_id_fkey(phone)';

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this._client);

  final SupabaseClient _client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppAuthException('You need to be logged in.');
    return id;
  }

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
  }) async {
    try {
      final dateStr =
          '${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}';

      final row = await _client
          .from('bookings')
          .insert({
            'customer_id': _requireUserId,
            'provider_id': providerId,
            'service_id': serviceId,
            'scheduled_date': dateStr,
            'scheduled_time': scheduledTime,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'description': description,
          })
          .select(_detailSelect)
          .single();
      return Booking.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('createBooking failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<Booking>> getMyBookingsAsCustomer() async {
    try {
      final rows = await _client
          .from('bookings')
          .select(_detailSelect)
          .eq('customer_id', _requireUserId)
          .order('created_at', ascending: false);
      return rows.map(Booking.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyBookingsAsCustomer failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<Booking>> getMyBookingsAsProvider(String providerId) async {
    try {
      final rows = await _client
          .from('bookings')
          .select(_detailSelect)
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return rows.map(Booking.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyBookingsAsProvider failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Booking> getBookingDetail(String bookingId) async {
    try {
      final row = await _client
          .from('bookings')
          .select(_detailSelect)
          .eq('id', bookingId)
          .single();
      return Booking.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getBookingDetail failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Stream<Booking> watchBooking(String bookingId) async* {
    // Realtime rows are plain columns with no joins, so the display fields
    // (business name, service name, customer phone) would go missing on
    // every live update if parsed on their own. Fetch the joined detail
    // once and re-attach it to each raw realtime row instead.
    final initial = await getBookingDetail(bookingId);
    yield initial;

    await for (final rows
        in _client.from('bookings').stream(primaryKey: ['id']).eq('id', bookingId)) {
      if (rows.isEmpty) continue;
      yield Booking.fromJson({
        ...rows.first,
        'provider_profiles': {
          'business_name': initial.providerBusinessName,
          'user_id': initial.providerUserId,
        },
        'services': {'name_en': initial.serviceNameEn, 'name_am': initial.serviceNameAm},
        'users': {'phone': initial.customerPhone},
      });
    }
  }

  @override
  Future<void> updateStatus(
    String bookingId,
    BookingStatus newStatus, {
    String? cancellationReason,
    double? finalPrice,
  }) async {
    try {
      final updates = <String, dynamic>{'status': newStatus.value};
      if (cancellationReason != null) updates['cancellation_reason'] = cancellationReason;
      if (finalPrice != null) updates['final_price'] = finalPrice;

      await _client.from('bookings').update(updates).eq('id', bookingId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('updateStatus failed', error: e, stackTrace: st);
      // The trigger's business-rule rejections are meant to be read by a
      // human (spec section 9's validation messages), so surface them
      // instead of the generic network error.
      if (e.code == 'P0001') {
        throw ValidationException(e.message);
      }
      throw const NetworkException();
    }
  }
}
