import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/subscription.dart';
import '../domain/subscription_plan.dart';
import '../domain/subscription_repository.dart';

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final rows = await _client.rpc('get_subscription_plans') as List;
      return rows
          .map((row) => SubscriptionPlan.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getPlans failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Subscription?> getMySubscription(String providerId) async {
    try {
      final row = await _client
          .from('subscriptions')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : Subscription.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMySubscription failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  // The `subscriptions` row itself isn't written here — stripe-webhook does
  // that once Stripe confirms the invoice server-side (same reasoning as
  // SupabasePaymentRepository.initializeDigitalPayment), so this polls
  // briefly after the sheet reports success rather than assuming the row
  // is already active.
  @override
  Future<Subscription> subscribe(String providerId, String plan) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'stripe-create-subscription',
        body: {'providerId': providerId, 'plan': plan},
      );
    } on FunctionException catch (e, st) {
      AppLogger.error(
        'stripe-create-subscription failed',
        error: e,
        stackTrace: st,
      );
      final details = e.details;
      final message = details is Map && details['error'] is String
          ? details['error'] as String
          : 'Could not start the subscription. Please try again.';
      throw ValidationException(message);
    }

    final clientSecret = (response.data as Map)['clientSecret'] as String?;
    if (clientSecret == null) {
      throw const ValidationException(
        'Could not start the subscription. Please try again.',
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

    for (var attempt = 0; attempt < 5; attempt++) {
      final subscription = await getMySubscription(providerId);
      if (subscription != null && subscription.isActive) return subscription;
      await Future.delayed(const Duration(seconds: 1));
    }

    throw const ValidationException(
      'Payment succeeded, but confirmation is taking longer than expected. '
      'Please check back shortly.',
    );
  }
}
