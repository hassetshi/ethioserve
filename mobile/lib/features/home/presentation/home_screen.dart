import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Phase 1 placeholder: proves routing/localization/theme work end to end.
///
/// The real layout (categories, nearby/featured providers, recent bookings —
/// spec section 14) is built in Phase 3 (categories/services) and Phase 5
/// (provider search), once there is real data to back it.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeGreetingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.aiSearchLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
