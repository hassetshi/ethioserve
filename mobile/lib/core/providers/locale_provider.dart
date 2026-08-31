import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory locale selection for Phase 1.
///
/// This becomes durable in Phase 2 once auth/profiles exist: the choice
/// will be written to `users.language_code` / `profiles.preferred_language`
/// (see supabase/migrations) instead of living only in app memory.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void select(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

const supportedLocales = [Locale('en'), Locale('am')];
