import 'category.dart';
import 'service.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();

  Future<List<Service>> getServicesByCategory(String categoryId);

  Future<Category> getCategory(String categoryId);
}
