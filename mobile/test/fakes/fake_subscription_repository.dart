import 'package:ethioserve/features/subscriptions/domain/subscription.dart';
import 'package:ethioserve/features/subscriptions/domain/subscription_plan.dart';
import 'package:ethioserve/features/subscriptions/domain/subscription_repository.dart';

class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    this.plans = const [
      SubscriptionPlan(
        plan: 'professional',
        priceUsd: 29,
        interval: 'month',
        stripePriceId: 'price_professional_test',
      ),
      SubscriptionPlan(
        plan: 'premium',
        priceUsd: 79,
        interval: 'month',
        stripePriceId: 'price_premium_test',
      ),
    ],
    this.mySubscription,
  });

  List<SubscriptionPlan> plans;
  Subscription? mySubscription;

  @override
  Future<List<SubscriptionPlan>> getPlans() async => plans;

  @override
  Future<Subscription?> getMySubscription(String providerId) async =>
      mySubscription;

  @override
  Future<Subscription> subscribe(String providerId, String plan) async {
    final subscription = Subscription(
      id: 'sub-1',
      providerId: providerId,
      plan: plan,
      price: plans.firstWhere((p) => p.plan == plan).priceUsd,
      status: 'active',
    );
    mySubscription = subscription;
    return subscription;
  }
}
