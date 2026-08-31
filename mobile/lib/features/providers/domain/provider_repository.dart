import 'provider_detail.dart';
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
}
