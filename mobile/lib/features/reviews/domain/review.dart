class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.providerId,
    required this.rating,
    this.comment,
    this.providerResponse,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerId;
  final String providerId;
  final int rating;
  final String? comment;
  final String? providerResponse;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        customerId: json['customer_id'] as String,
        providerId: json['provider_id'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        providerResponse: json['provider_response'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
