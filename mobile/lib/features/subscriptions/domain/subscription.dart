/// A provider's listing subscription. "Never subscribed" is represented by
/// no row existing at all (`SubscriptionRepository.getMySubscription`
/// returns `null`), not by `plan == 'free'` — a `free` row with
/// `status == 'active'` is a real launch-promotion listing and counts in
/// search alongside 'professional' and 'premium'.
class Subscription {
  const Subscription({
    required this.id,
    required this.providerId,
    required this.plan,
    required this.price,
    required this.status,
    this.currentPeriodEnd,
  });

  final String id;
  final String providerId;
  final String plan;
  final double price;
  final String status;
  final DateTime? currentPeriodEnd;

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    providerId: json['provider_id'] as String,
    plan: json['plan'] as String,
    price: (json['price'] as num).toDouble(),
    status: json['status'] as String,
    currentPeriodEnd: json['current_period_end'] == null
        ? null
        : DateTime.parse(json['current_period_end'] as String),
  );
}
