import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_provider_repository.dart';
import '../domain/provider_detail.dart';
import '../domain/provider_document.dart';
import '../domain/provider_repository.dart';
import '../domain/provider_summary.dart';

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return SupabaseProviderRepository(Supabase.instance.client);
});

final providerDetailProvider =
    FutureProvider.autoDispose.family<ProviderDetail, String>((ref, providerId) {
  return ref.watch(providerRepositoryProvider).getProviderDetail(providerId);
});

/// A record (not a class) so Riverpod's family caching gets structural
/// equality for free — two searches with the same filters share one cached
/// result instead of re-fetching.
typedef ProviderSearchFilters = ({
  String? categoryId,
  String? serviceId,
  String? cityId,
  double? lat,
  double? lng,
  double? minRating,
});

final providerSearchResultsProvider = FutureProvider.autoDispose
    .family<List<ProviderSummary>, ProviderSearchFilters>((ref, filters) {
  return ref.watch(providerRepositoryProvider).searchProviders(
        categoryId: filters.categoryId,
        serviceId: filters.serviceId,
        cityId: filters.cityId,
        lat: filters.lat,
        lng: filters.lng,
        minRating: filters.minRating,
      );
});

/// The current user's own provider_profiles.id, or `null` if they haven't
/// registered as a provider yet. Drives router redirects and Profile's
/// "Become a provider" entry point.
final myProviderIdProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(providerRepositoryProvider).getMyProviderId();
});

final myDocumentsProvider =
    FutureProvider.autoDispose.family<List<ProviderDocument>, String>((ref, providerId) {
  return ref.watch(providerRepositoryProvider).getMyDocuments(providerId);
});
