import 'category.dart';
import 'city.dart';
import 'service.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();

  Future<List<Service>> getServicesByCategory(String categoryId);

  Future<Category> getCategory(String categoryId);

  /// Active launch cities (spec section 3: only Addis Ababa is active at
  /// launch; future cities are additive rows here, not schema changes).
  Future<List<City>> getCities();

  /// Services whose name matches [query] (English or Amharic), for the
  /// Home search field. This is plain substring matching, not the AI
  /// interpretation pipeline (spec section 15, Phase 11) — that's a
  /// separate, additional entry point layered on top later, not a
  /// replacement for this one.
  Future<List<Service>> searchServices(String query);
}
