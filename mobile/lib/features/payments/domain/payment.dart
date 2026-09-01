class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.platformFee,
    required this.providerAmount,
    required this.currency,
    required this.paymentProvider,
    this.transactionReference,
    required this.status,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final double platformFee;
  final double providerAmount;
  final String currency;
  final String paymentProvider;
  final String? transactionReference;
  final String status;
  final DateTime? paidAt;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
    id: json['id'] as String,
    bookingId: json['booking_id'] as String,
    amount: (json['amount'] as num).toDouble(),
    platformFee: (json['platform_fee'] as num).toDouble(),
    providerAmount: (json['provider_amount'] as num).toDouble(),
    currency: json['currency'] as String,
    paymentProvider: json['payment_provider'] as String,
    transactionReference: json['transaction_reference'] as String?,
    status: json['status'] as String,
    paidAt: json['paid_at'] == null
        ? null
        : DateTime.parse(json['paid_at'] as String),
  );
}
