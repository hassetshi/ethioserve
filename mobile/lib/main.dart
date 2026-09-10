import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/logging/app_logger.dart';
import 'core/providers/push_notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // dart:io's TLS stack (what Supabase/Stripe's HTTP calls actually use) has
  // its own independent trust store - it does NOT consult Android's
  // platform certificate store, so installing a user CA cert for local
  // TLS-intercepting software (antivirus/corporate proxy SSL scanning) has
  // no effect here, even though it fixes native Android apps (Chrome,
  // WebView) via android/app/src/debug/res/xml/network_security_config.xml.
  // Confirmed live: Chrome succeeded against the real Supabase URL after
  // installing the intercepting AV's root cert as a user credential: the
  // Flutter app still failed with the exact same cert installed, because
  // this is a separate trust store entirely - not a config mistake. Mirrors
  // that file's scope and reasoning at the Dart layer instead: relax
  // certificate validation only in debug builds (kDebugMode is compiled out
  // of release builds entirely), never in release.
  if (kDebugMode) {
    HttpOverrides.global = _DevHttpOverrides();
  }

  // No-ops (just calls _runApp directly) until a real Sentry DSN is filled
  // in via dart-define - see EnvConfig.sentryDsn.
  if (EnvConfig.sentryDsn.isEmpty) {
    await _runApp();
    return;
  }
  await SentryFlutter.init((options) {
    options.dsn = EnvConfig.sentryDsn;
    options.environment = EnvConfig.environment.name;
  }, appRunner: _runApp);
}

Future<void> _runApp() async {
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

/// Debug-only - see the kDebugMode check in main() for why this exists.
class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
