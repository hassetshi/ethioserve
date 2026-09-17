import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main.dart`'s `_runApp()` with the real resolved instance
/// before the widget tree is built, so every other provider can read it
/// synchronously despite `SharedPreferences.getInstance()` itself being
/// async — the standard Riverpod pattern for this.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main() before use',
  );
});
