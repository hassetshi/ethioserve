import 'package:flutter_stripe/flutter_stripe.dart';
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
      final paymentId = await _client.rpc(
        'record_cash_payment',
        params: {'p_booking_id': bookingId},
      ) as String;
      final row = await _client
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();
      return Payment.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('recordCashPayment failed', error: e, stackTrace: st);
      if (e.code == 'P0001') throw ValidationException(e.message);
      throw const NetworkException();
    }
  }

  // Card payment via Stripe's PaymentSheet. The `payments` row itself isn't
  // written here — stripe-webhook does that once Stripe confirms the charge
  // server-side (see that function's own comment on why), so this method
  // polls briefly after the sheet reports success rather than assuming the
  // row already exists.
  @override
  Future<Payment> initializeDigitalPayment(String bookingId) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'stripe-create-payment-intent',
        body: {'bookingId': bookingId},
      );
    } on FunctionException catch (e, st) {
      AppLogger.error(
        'stripe-create-payment-intent failed',
        error: e,
        stackTrace: st,
      );
      final details = e.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : 'Could not start the payment. Please try again.';
      throw ValidationException(message);
    }

    final clientSecret = (response.data as Map)['clientSecret'] as String?;
    if (clientSecret == null) {
      throw const ValidationException(
        'Could not start the payment. Please try again.',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'EthioServe',
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e, st) {
      AppLogger.error('Stripe payment sheet failed', error: e, stackTrace: st);
      throw ValidationException(
        e.error.localizedMessage ?? 'Payment was not completed.',
      );
    }

    // The webhook that writes the `payments` row usually lands within a
    // second or two of the charge succeeding, but it's a separate async
    // request from Stripe to our Edge Function, not something this call can
    // wait on directly - so poll briefly rather than assuming it's already
    // there.
    for (var attempt = 0; attempt < 5; attempt++) {
      final payment = await getPaymentForBooking(bookingId);
      if (payment != null) return payment;
      await Future.delayed(const Duration(seconds: 1));
    }

    throw const ValidationException(
      'Payment succeeded, but confirmation is taking longer than expected. '
      'Please check back shortly.',
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
