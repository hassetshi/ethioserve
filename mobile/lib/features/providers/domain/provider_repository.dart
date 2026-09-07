import 'dart:typed_data';

import 'provider_detail.dart';
import 'provider_document.dart';
import 'provider_summary.dart';

abstract class ProviderRepository {
  Future<ProviderDetail> getProviderDetail(String providerId);

  /// Server-side filtered/paginated provider search (spec section 17): the
  /// Category-browse flow (Phase 3), the Search flow (Phase 5), and any
  /// future entry point (AI search, Phase 11) all call this one method
  /// instead of each re-implementing filtering — it's a thin pass-through
  /// to the `search_providers` RPC.
  Future<List<ProviderSummary>> searchProviders({
    String? categoryId,
    String? serviceId,
    String? cityId,
    double? lat,
    double? lng,
    double radiusKm = 25,
    double? minRating,
    bool verifiedOnly = true,
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
