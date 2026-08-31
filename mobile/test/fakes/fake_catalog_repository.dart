import 'package:ethioserve/features/catalog/domain/catalog_repository.dart';
import 'package:ethioserve/features/catalog/domain/category.dart';
import 'package:ethioserve/features/catalog/domain/city.dart';
import 'package:ethioserve/features/catalog/domain/service.dart';

class FakeCatalogRepository implements CatalogRepository {
  final categories = const [
    Category(id: 'cat-1', nameEn: 'Plumbing', nameAm: 'ቧንቧ ስራ'),
    Category(id: 'cat-2', nameEn: 'Electrical', nameAm: 'ኤሌክትሪክ ስራ'),
  ];

  @override
  Future<List<Category>> getCategories() async => categories;

  @override
  Future<Category> getCategory(String categoryId) async =>
      categories.firstWhere((c) => c.id == categoryId);

  @override
  Future<List<Service>> getServicesByCategory(String categoryId) async => [
        const Service(
          id: 'svc-1',
          categoryId: 'cat-1',
          nameEn: 'Pipe Repair',
          nameAm: 'የቧንቧ ጥገና',
        ),
      ];

  @override
  Future<List<City>> getCities() async => const [
        City(id: 'city-1', nameEn: 'Addis Ababa', nameAm: 'አዲስ አበባ'),
      ];

  @override
  Future<List<Service>> searchServices(String query) async {
    final services = await getServicesByCategory('cat-1');
    return services
        .where((s) => s.nameEn.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
