import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({this.onLanguageSelected, super.key});

  /// Called after a language is picked, instead of the default first-launch
  /// behavior of `context.push('/')` (letting the router redirect decide
  /// login vs. home). Set this when reusing the screen from somewhere a
  /// user already has a locale and an account - e.g. Profile's "Language"
  /// entry point - so picking a language returns to where they came from
  /// instead of re-running the first-launch redirect. Also used to decide
  /// whether this screen shows a back arrow (see `build` below) - only
  /// non-null when this instance was reached via `push`, so `canPop()` is
  /// true.
  final VoidCallback? onLanguageSelected;

  void _select(WidgetRef ref, BuildContext context, Locale locale) {
    ref.read(localeProvider.notifier).select(locale);
    if (onLanguageSelected != null) {
      onLanguageSelected!();
    } else {
      // push (not go) so `/language` stays in history - the router
      // redirect resolves '/' to home (or role-home) as the one new
      // pushed entry, giving a stack of [/language, /home]. That lets
      // Back from Home return to Language, instead of discarding it.
      context.push('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // First-launch (onLanguageSelected null): this is the initial route,
      // nothing to go back to, no AppBar. Reached via push from Profile/Home
      // ("change language"): canPop() is true, so a default AppBar's
      // automatic back arrow is exactly right.
      appBar: onLanguageSelected != null ? AppBar() : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.languageSelectionTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => _select(ref, context, const Locale('en')),
                child: const Text('English'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _select(ref, context, const Locale('am')),
                child: const Text('አማርኛ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
