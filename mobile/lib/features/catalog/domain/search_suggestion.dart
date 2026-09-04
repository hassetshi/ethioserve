/// Whether a [SearchSuggestion] resolves to a category or a single service -
/// determines which `/…/providers` route it pushes to.
enum SearchSuggestionType { category, service }

/// A single typeahead result for the Home search field, combining both
/// [SearchSuggestionType.category] and [SearchSuggestionType.service]
/// matches into one list the user picks from.
class SearchSuggestion {
  const SearchSuggestion({
    required this.type,
    required this.id,
    required this.nameEn,
    required this.nameAm,
  });

  final SearchSuggestionType type;
  final String id;
  final String nameEn;
  final String nameAm;

  String localizedName(String languageCode) =>
      languageCode == 'am' ? nameAm : nameEn;
}
