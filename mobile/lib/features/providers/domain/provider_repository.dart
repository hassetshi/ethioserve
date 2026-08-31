import 'dart:typed_data';

import 'provider_detail.dart';
import 'provider_document.dart';
import 'provider_summary.dart';

abstract class ProviderRepository {
  Future<ProviderDetail> getProviderDetail(String providerId);

  /// Providers offering [serviceId], verified-only, nearest/highest-rated
  /// first. Backed by the `search_providers` RPC so this and the future
  /// Phase 5 search screens share one server-side query, not two.
  Future<List<ProviderSummary>> listProvidersForService(
    String serviceId, {
    int limit = 20,
    int offset = 0,
  });

  /// The current user's own provider_profiles.id, or `null` if they haven't
  /// registered as a provider.
  Future<String?> getMyProviderId();

  /// Registers the current user as a provider. Throws [AppException] if
  /// they already are one. Promotes `users.role` to 'provider' server-side
  /// (see the `register_as_provider` migration) — the client never sets its
  /// own role.
  Future<String> registerAsProvider({
    required String businessName,
    String? descriptionEn,
    String? descriptionAm,
    required String phone,
    String? address,
    required String cityId,
    double? latitude,
    double? longitude,
  });

  Future<void> addOfferedService({
    required String providerId,
    required String serviceId,
    double? minPrice,
    double? maxPrice,
    required String pricingType,
  });

  Future<List<ProviderDocument>> getMyDocuments(String providerId);

  Future<void> uploadVerificationDocument({
    required String providerId,
    required String documentType,
    required Uint8List bytes,
    required String fileExtension,
  });
}
