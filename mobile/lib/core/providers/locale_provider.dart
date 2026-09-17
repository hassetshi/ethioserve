import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_preferences_provider.dart';

/// Persisted device-local locale selection, via `shared_preferences`
/// (not `users.language_code`/`profiles.preferred_language` - those exist
/// in the DB but syncing to them would mean cross-device sync, which
/// wasn't asked for, and `Profile.toJson()` always serializes required
/// `first_name`/`last_name`, so a naive language-only upsert there risks
/// nulling out a user's name or violating a not-null constraint if no
/// profile row exists yet. Revisit only if cross-device sync is explicitly
/// wanted later.
class LocaleNotifier extends Notifier<Locale?> {
  static const _prefsKey = 'language_code';

  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    return code == null ? null : Locale(code);
  }

  void select(Locale locale) {
    state = locale;
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

const supportedLocales = [Locale('en'), Locale('am')];
