import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/city.dart';
import '../domain/service.dart';

class SupabaseCatalogRepository implements CatalogRepository {
  SupabaseCatalogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      return rows.map(Category.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getCategories failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Category> getCategory(String categoryId) async {
    try {
      final row =
          await _client.from('categories').select().eq('id', categoryId).single();
      return Category.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getCategory failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<Service>> getServicesByCategory(String categoryId) async {
    try {
      final rows = await _client
          .from('services')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('name_en');
      return rows.map(Service.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getServicesByCategory failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<City>> getCities() async {
    try {
      final rows = await _client
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('display_order');
      return rows.map(City.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getCities failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
