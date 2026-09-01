import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_catalog_repository.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/city.dart';
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
