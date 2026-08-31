import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (EnvConfig.isConfigured) {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      publishableKey: EnvConfig.supabaseAnonKey,
    );
  } else {
    // Expected until a real dev Supabase project is connected (see
    // LOCAL_DEVELOPMENT.md). The UI still runs so screens/navigation/
    // localization can be built and tested without a backend.
    AppLogger.warning(
      'Supabase is not configured (no SUPABASE_URL/SUPABASE_ANON_KEY '
      'dart-define). Running with backend features disabled.',
    );
  }

  runApp(const ProviderScope(child: EthioServeApp()));
}
