import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
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
                onPressed: () {
                  ref.read(localeProvider.notifier).select(const Locale('en'));
                  // Router redirect decides where to actually land (login
                  // vs. home) based on auth state.
                  context.go('/');
                },
                child: const Text('English'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.read(localeProvider.notifier).select(const Locale('am'));
                  // Router redirect decides where to actually land (login
                  // vs. home) based on auth state.
                  context.go('/');
                },
                child: const Text('አማርኛ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
