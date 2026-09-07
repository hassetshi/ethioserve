import 'category.dart';
import 'city.dart';
import 'search_suggestion.dart';
import 'service.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();

  Future<List<Service>> getServicesByCategory(String categoryId);

  Future<Category> getCategory(String categoryId);

  /// A single service by id, for showing what the user searched for on the
  /// provider-results screen (that screen only receives a serviceId/
  /// categoryId via the route, not a name).
  Future<Service> getService(String serviceId);

  /// Active launch cities (spec section 3: only Washington, DC is active at
  /// launch — the initial market is Ethiopian-American businesses/customers
  /// in the US; future cities, including an eventual return to Ethiopia
  /// itself, are additive rows here, not schema changes).
  Future<List<City>> getCities();

  /// Services whose name matches [query] (English or Amharic), for the
  /// Home search field. This is plain substring matching, not the AI
  /// interpretation pipeline (spec section 15, Phase 11) — that's a
  /// separate, additional entry point layered on top later, not a
  /// replacement for this one.
  Future<List<Service>> searchServices(String query);

  /// Category and service name matches for [query] (English or Amharic),
  /// combined into one ranked list for the Home field's inline typeahead
  /// dropdown. Same plain substring matching as [searchServices], extended
  /// to also cover `categories` so a broad term like "hair" surfaces the
  /// Hair Salon category itself, not just individual services under it.
  Future<List<SearchSuggestion>> searchSuggestions(String query);
}
