import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/catalog_repository.dart';
import '../domain/category.dart';
import '../domain/city.dart';
import '../domain/search_suggestion.dart';
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
      final row = await _client
          .from('categories')
          .select()
          .eq('id', categoryId)
          .single();
      return Category.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getCategory failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Service> getService(String serviceId) async {
    try {
      final row = await _client
          .from('services')
          .select()
          .eq('id', serviceId)
          .single();
      return Service.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getService failed', error: e, stackTrace: st);
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

  @override
  Future<List<Service>> searchServices(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    try {
      // Two separate .ilike() calls (rather than building an .or() filter
      // string by interpolation) so characters like ',' or '(' in [query]
      // can't corrupt the PostgREST filter syntax.
      final pattern = '%$trimmed%';
      final results = await Future.wait([
        _client
            .from('services')
            .select()
            .eq('is_active', true)
            .ilike('name_en', pattern)
            .limit(20),
        _client
            .from('services')
            .select()
            .eq('is_active', true)
            .ilike('name_am', pattern)
            .limit(20),
      ]);

      final seenIds = <String>{};
      final services = <Service>[];
      for (final rows in results) {
        for (final row in rows) {
          final service = Service.fromJson(row);
          if (seenIds.add(service.id)) services.add(service);
        }
      }
      services.sort((a, b) => a.nameEn.compareTo(b.nameEn));
      return services;
    } on PostgrestException catch (e, st) {
      AppLogger.error('searchServices failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<SearchSuggestion>> searchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    try {
      // Four separate .ilike() calls (rather than an .or() filter string)
      // for the same reason as searchServices: [query] reaches PostgREST
      // filter syntax unescaped otherwise.
      final pattern = '%$trimmed%';
      final results = await Future.wait([
        _client
            .from('categories')
            .select()
            .eq('is_active', true)
            .ilike('name_en', pattern)
            .limit(8),
        _client
            .from('categories')
            .select()
            .eq('is_active', true)
            .ilike('name_am', pattern)
            .limit(8),
        _client
            .from('services')
            .select()
            .eq('is_active', true)
            .ilike('name_en', pattern)
            .limit(8),
        _client
            .from('services')
            .select()
            .eq('is_active', true)
            .ilike('name_am', pattern)
            .limit(8),
      ]);

      final seenIds = <String>{};
      final suggestions = <SearchSuggestion>[];
      for (final rows in [results[0], results[1]]) {
        for (final row in rows) {
          final category = Category.fromJson(row);
          if (seenIds.add('category:${category.id}')) {
            suggestions.add(
              SearchSuggestion(
                type: SearchSuggestionType.category,
                id: category.id,
                nameEn: category.nameEn,
                nameAm: category.nameAm,
              ),
            );
          }
        }
      }
      for (final rows in [results[2], results[3]]) {
        for (final row in rows) {
          final service = Service.fromJson(row);
          if (seenIds.add('service:${service.id}')) {
            suggestions.add(
              SearchSuggestion(
                type: SearchSuggestionType.service,
                id: service.id,
                nameEn: service.nameEn,
                nameAm: service.nameAm,
              ),
            );
          }
        }
      }
      suggestions.sort((a, b) => a.nameEn.compareTo(b.nameEn));
      return suggestions.take(10).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('searchSuggestions failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
