import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'provider_providers.dart';

/// Reached from Profile's "Become a provider" button. A real business might
/// already be pre-seeded and unclaimed (see provider_leads/
/// provider_claim_requests) — this screen offers claiming that listing as
/// an alternative to registering a brand-new one, and short-circuits to the
/// claim-status screen if the user already has a claim in flight.
class ChooseProviderPathScreen extends ConsumerWidget {
  const ChooseProviderPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimStatusAsync = ref.watch(myClaimStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Become a provider')),
      body: SafeArea(
        child: claimStatusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Something went wrong. Please try again.'),
          ),
          data: (claimStatus) {
            if (claimStatus != null && !claimStatus.isRejected) {
              // Rejected claims fall through to let the user try again;
              // pending ones (or, briefly, approved ones before the
              // provider row shows up) go straight to the status screen.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/provider/claim/status');
              });
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Is your business already listed on EthioServe, or is '
                    'this your first time?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/provider/claim/search'),
                    child: const Text('Claim an existing listing'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/provider/register'),
                    child: const Text('Register a new business'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
