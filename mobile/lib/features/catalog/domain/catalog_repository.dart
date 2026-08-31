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
}
