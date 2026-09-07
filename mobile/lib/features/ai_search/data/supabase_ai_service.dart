import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/ai_search_result.dart';
import '../domain/ai_service.dart';

class SupabaseAIService implements AIService {
  SupabaseAIService(this._client);

  final SupabaseClient _client;

  @override
  Future<AiSearchResult> interpretSearchQuery(String query) async {
    try {
      final response = await _client.functions.invoke(
        'ai-search',
        body: {'query': query},
      );
      return AiSearchResult.fromJson(response.data as Map<String, dynamic>);
    } on FunctionException catch (e, st) {
      AppLogger.error('interpretSearchQuery failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
