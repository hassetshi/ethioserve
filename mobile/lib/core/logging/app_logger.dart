import 'dart:developer' as developer;

/// Centralized logging (spec section 29).
///
/// Never pass passwords, OTP codes, payment secrets, API keys, or other
/// sensitive personal information to these methods, even in [context] —
/// this is the one chokepoint where that rule is enforced by convention.
class AppLogger {
  const AppLogger._();

  static void info(String message, {String name = 'EthioServe'}) {
    developer.log(message, name: name, level: 800);
  }

  static void warning(String message, {String name = 'EthioServe'}) {
    developer.log(message, name: name, level: 900);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'EthioServe',
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
