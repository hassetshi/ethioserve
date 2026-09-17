/// Lightweight provider info for list contexts (e.g. "providers offering
/// this service"), sourced from the `search_providers` RPC (spec section 17:
/// server-side filtering/pagination, never a bulk client-side dump).
class ProviderSummary {
  const ProviderSummary({
    required this.providerId,
    required this.businessName,
    this.descriptionEn,
    this.descriptionAm,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
    this.distanceKm,
    this.phone,
    this.address,
    this.isOpenNow,
  });

  final String providerId;
  final String businessName;
  final String? descriptionEn;
  final String? descriptionAm;
  final double rating;
  final int reviewCount;
  final String verificationStatus;
  final double? distanceKm;
  final String? phone;
  final String? address;

  /// Null means "no hours on file" (most real providers today), not
  /// "closed" - see 20260916000032_search_providers_contact_and_hours.sql.
  final bool? isOpenNow;

  factory ProviderSummary.fromJson(Map<String, dynamic> json) =>
      ProviderSummary(
        providerId: json['provider_id'] as String,
        businessName: json['business_name'] as String,
        descriptionEn: json['description_en'] as String?,
        descriptionAm: json['description_am'] as String?,
        rating: (json['rating'] as num).toDouble(),
        reviewCount: json['review_count'] as int,
        verificationStatus: json['verification_status'] as String,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        isOpenNow: json['is_open_now'] as bool?,
      );
}
