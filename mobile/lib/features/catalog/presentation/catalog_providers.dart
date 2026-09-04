import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_catalog_repository.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/city.dart';
import '../domain/search_suggestion.dart';
import '../domain/service.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return SupabaseCatalogRepository(Supabase.instance.client);
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCategories();
});

final categoryProvider = FutureProvider.autoDispose.family<Category, String>((
  ref,
  categoryId,
) {
  return ref.watch(catalogRepositoryProvider).getCategory(categoryId);
});

final serviceProvider = FutureProvider.autoDispose.family<Service, String>((
  ref,
  serviceId,
) {
  return ref.watch(catalogRepositoryProvider).getService(serviceId);
});

final servicesByCategoryProvider = FutureProvider.autoDispose
    .family<List<Service>, String>((ref, categoryId) {
      return ref
          .watch(catalogRepositoryProvider)
          .getServicesByCategory(categoryId);
    });

final citiesProvider = FutureProvider.autoDispose<List<City>>((ref) {
  return ref.watch(catalogRepositoryProvider).getCities();
});

final serviceSearchProvider = FutureProvider.autoDispose
    .family<List<Service>, String>((ref, query) {
      return ref.watch(catalogRepositoryProvider).searchServices(query);
    });

/// Backs the Home field's inline typeahead dropdown. Watched with an
/// already-debounced query (see [_HomeSearchFieldState._onQueryChanged]) so
/// this doesn't itself fire on every keystroke.
final searchSuggestionsProvider = FutureProvider.autoDispose
    .family<List<SearchSuggestion>, String>((ref, query) {
      return ref.watch(catalogRepositoryProvider).searchSuggestions(query);
    });
