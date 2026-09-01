import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/payment.dart';
import '../domain/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Payment> recordCashPayment(String bookingId) async {
    try {
      final paymentId = await _client.rpc('record_cash_payment', params: {
        'p_booking_id': bookingId,
      }) as String;
      final row =
          await _client.from('payments').select().eq('id', paymentId).single();
      return Payment.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('recordCashPayment failed', error: e, stackTrace: st);
      if (e.code == 'P0001') throw ValidationException(e.message);
      throw const NetworkException();
    }
  }

  @override
  Future<Payment> initializeDigitalPayment(String bookingId) async {
    throw const ValidationException(
      'Digital payments are not yet available. Please pay in cash for now.',
    );
  }

  @override
  Future<Payment?> getPaymentForBooking(String bookingId) async {
    try {
      final row = await _client
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      return row == null ? null : Payment.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getPaymentForBooking failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
