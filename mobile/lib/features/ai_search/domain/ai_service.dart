import 'ai_search_result.dart';

/// Vendor-agnostic AI search interpretation (spec sections 15-16). The
/// concrete implementation is a thin call to a server-side Edge Function —
/// never a direct call to an AI vendor's API from the client, since that
/// would require shipping the vendor's secret key in the app.
abstract class AIService {
  Future<AiSearchResult> interpretSearchQuery(String query);
}
