/// Compile-time environment configuration.
///
/// Values are injected via `--dart-define-from-file=.env.<environment>.json`
/// at build time (see LOCAL_DEVELOPMENT.md), never bundled as a readable
/// asset. Only the Supabase *anon* key belongs here — the service-role key
/// must never be compiled into the app (spec section 7/25).
enum AppEnvironment { development, staging, production }

class EnvConfig {
  const EnvConfig._();

  static const String _environmentName = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static AppEnvironment get environment => switch (_environmentName) {
    'staging' => AppEnvironment.staging,
    'production' => AppEnvironment.production,
    _ => AppEnvironment.development,
  };

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String aiApiUrl = String.fromEnvironment('AI_API_URL');

  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Publishable key only — safe to compile into the app, same reasoning as
  /// SUPABASE_ANON_KEY. The Stripe *secret* key never leaves the
  /// stripe-create-payment-intent Edge Function.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
