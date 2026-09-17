import 'package:ethioserve/core/providers/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `localeProvider` (`LocaleNotifier.build()`) reads `sharedPreferencesProvider`
/// on first use, so every widget test that reaches a screen watching
/// `localeProvider` — directly or via the app shell — needs this override in
/// its `ProviderScope`, or it throws `UnimplementedError`.
Future<Override> fakeSharedPreferencesOverride({
  Map<String, Object> values = const {},
}) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(prefs);
}
