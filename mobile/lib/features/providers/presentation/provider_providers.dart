import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_provider_repository.dart';
import '../domain/provider_detail.dart';
import '../domain/provider_repository.dart';
import '../domain/provider_summary.dart';

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return SupabaseProviderRepository(Supabase.instance.client);
});

final providerDetailProvider =
    FutureProvider.autoDispose.family<ProviderDetail, String>((ref, providerId) {
  return ref.watch(providerRepositoryProvider).getProviderDetail(providerId);
});

final providersForServiceProvider =
    FutureProvider.autoDispose.family<List<ProviderSummary>, String>((ref, serviceId) {
  return ref.watch(providerRepositoryProvider).listProvidersForService(serviceId);
});
