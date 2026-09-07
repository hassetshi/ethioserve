/// A purchasable listing plan, priced from platform_settings (spec: numbers
/// are admin-editable data, never hard-coded — see the booking commission
/// rate for the same convention). `stripePriceId` is null until
/// scripts/create-stripe-subscription-prices.mjs has run for this plan.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.plan,
    required this.priceUsd,
    required this.interval,
    this.stripePriceId,
  });

  final String plan;
  final double priceUsd;
  final String interval;
  final String? stripePriceId;

  bool get isAvailable => stripePriceId != null;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        plan: json['plan'] as String,
        priceUsd: (json['price_usd'] as num).toDouble(),
        interval: json['interval'] as String,
        stripePriceId: json['stripe_price_id'] as String?,
      );
}
