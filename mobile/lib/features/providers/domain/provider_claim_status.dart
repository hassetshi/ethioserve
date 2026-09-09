/// The current user's most recent request to claim a pre-seeded (unclaimed)
/// business listing — see [ProviderRepository.getMyClaimStatus]. Once a
/// claim is approved, `getMyProviderId()` starts returning non-null and the
/// user lands on the normal provider dashboard instead of a status screen.
class ProviderClaimStatus {
  const ProviderClaimStatus({
    required this.id,
    required this.providerId,
    required this.businessName,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String providerId;
  final String businessName;
  final String status;
  final String? rejectionReason;

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory ProviderClaimStatus.fromJson(Map<String, dynamic> json) =>
      ProviderClaimStatus(
        id: json['id'] as String,
        providerId: json['provider_id'] as String,
        businessName:
            (json['provider_profiles'] as Map<String, dynamic>)['business_name']
                as String,
        status: json['status'] as String,
        rejectionReason: json['rejection_reason'] as String?,
      );
}
