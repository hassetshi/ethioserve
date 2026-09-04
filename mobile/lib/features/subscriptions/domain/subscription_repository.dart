import 'subscription.dart';
import 'subscription_plan.dart';

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();

  /// The provider's most recent subscription row, or `null` if they've never
  /// subscribed. May be `pending` while Stripe confirms the first payment.
  Future<Subscription?> getMySubscription(String providerId);

  /// Starts a Stripe Subscription and presents the native PaymentSheet to
  /// confirm it, then polls until the webhook has recorded the result.
  /// Throws a [ValidationException]-style error with a message safe to show
  /// the user if the provider cancels or the charge fails.
  Future<Subscription> subscribe(String providerId, String plan);
}
