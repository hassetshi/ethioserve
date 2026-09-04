/// A provider's listing subscription. `plan == 'free'` (the table's
/// default) means "never subscribed" — search only considers 'professional'
/// and 'premium' plans with status 'active'.
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
