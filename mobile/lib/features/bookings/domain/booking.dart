import 'booking_status.dart';

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.providerId,
    required this.serviceId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.customerNotes,
    this.providerNotes,
    this.estimatedPrice,
    this.finalPrice,
    required this.status,
    this.cancellationReason,
    this.completedAt,
    required this.createdAt,
    this.providerBusinessName,
    this.serviceNameEn,
    this.serviceNameAm,
    this.customerPhone,
  });

  final String id;
  final String customerId;
  final String providerId;
  final String serviceId;

  /// Raw `YYYY-MM-DD` from Postgres `date`.
  final String scheduledDate;

  /// Raw `HH:MM:SS` from Postgres `time`.
  final String scheduledTime;

  final String address;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String? customerNotes;
  final String? providerNotes;
  final double? estimatedPrice;
  final double? finalPrice;
  final BookingStatus status;
  final String? cancellationReason;
  final DateTime? completedAt;
  final DateTime createdAt;

  // Populated only when the query joined these; null otherwise.
  final String? providerBusinessName;
  final String? serviceNameEn;
  final String? serviceNameAm;
  final String? customerPhone;

  DateTime get scheduledDateTime => DateTime.parse('${scheduledDate}T$scheduledTime');

  String serviceName(String languageCode) =>
      (languageCode == 'am' ? serviceNameAm : serviceNameEn) ?? 'Service';

  factory Booking.fromJson(Map<String, dynamic> json) {
    final provider = json['provider_profiles'] as Map<String, dynamic>?;
    final service = json['services'] as Map<String, dynamic>?;
    final customerUser = json['users'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      providerId: json['provider_id'] as String,
      serviceId: json['service_id'] as String,
      scheduledDate: json['scheduled_date'] as String,
      scheduledTime: json['scheduled_time'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      customerNotes: json['customer_notes'] as String?,
      providerNotes: json['provider_notes'] as String?,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      status: BookingStatus.fromValue(json['status'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      providerBusinessName: provider?['business_name'] as String?,
      serviceNameEn: service?['name_en'] as String?,
      serviceNameAm: service?['name_am'] as String?,
      customerPhone: customerUser?['phone'] as String?,
    );
  }
}
