class ProviderOfferedService {
  const ProviderOfferedService({
    required this.serviceId,
    required this.nameEn,
    required this.nameAm,
    this.minPrice,
    this.maxPrice,
    required this.pricingType,
  });

  final String serviceId;
  final String nameEn;
  final String nameAm;
  final double? minPrice;
  final double? maxPrice;
  final String pricingType;

  factory ProviderOfferedService.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>;
    return ProviderOfferedService(
      serviceId: service['id'] as String,
      nameEn: service['name_en'] as String,
      nameAm: service['name_am'] as String,
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      pricingType: json['pricing_type'] as String,
    );
  }
}

class ProviderDetail {
  const ProviderDetail({
    required this.id,
    required this.businessName,
    this.descriptionEn,
    this.descriptionAm,
    this.address,
    this.cityNameEn,
    this.cityNameAm,
    this.phone,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.verificationStatus,
    required this.services,
    required this.photoUrls,
  });

  final String id;
  final String businessName;
  final String? descriptionEn;
  final String? descriptionAm;
  final String? address;
  final String? cityNameEn;
  final String? cityNameAm;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final String verificationStatus;
  final List<ProviderOfferedService> services;
  final List<String> photoUrls;

  bool get isVerified => verificationStatus == 'verified';

  factory ProviderDetail.fromJson(
    Map<String, dynamic> json, {
    required List<ProviderOfferedService> services,
    required List<String> photoUrls,
  }) {
    final city = json['cities'] as Map<String, dynamic>?;
    return ProviderDetail(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      descriptionEn: json['description_en'] as String?,
      descriptionAm: json['description_am'] as String?,
      address: json['address'] as String?,
      cityNameEn: city?['name_en'] as String?,
      cityNameAm: city?['name_am'] as String?,
      phone: json['phone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      verificationStatus: json['verification_status'] as String,
      services: services,
      photoUrls: photoUrls,
    );
  }
}
