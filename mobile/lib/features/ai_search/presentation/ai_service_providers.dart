import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_ai_service.dart';
import '../domain/ai_service.dart';

final aiServiceProvider = Provider<AIService>((ref) {
  return SupabaseAIService(Supabase.instance.client);
});
