import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'core/providers/push_notification_provider.dart';

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

  if (EnvConfig.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = EnvConfig.stripePublishableKey;
    await Stripe.instance.applySettings();
  } else {
    AppLogger.warning(
      'Stripe is not configured (no STRIPE_PUBLISHABLE_KEY dart-define). '
      'Digital payment will be unavailable.',
    );
  }

  // A single container, created before runApp so push init can happen
  // ahead of the first frame, then handed to the widget tree via
  // UncontrolledProviderScope rather than creating a second container.
  final container = ProviderContainer();
  await container.read(pushNotificationServiceProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EthioServeApp(),
    ),
  );
}
