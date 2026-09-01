import 'package:ethioserve/features/ai_search/domain/ai_search_result.dart';
import 'package:ethioserve/features/ai_search/domain/ai_service.dart';

class FakeAIService implements AIService {
  FakeAIService(this.result);

  final AiSearchResult result;

  @override
  Future<AiSearchResult> interpretSearchQuery(String query) async => result;
}
