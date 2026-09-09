import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'provider_providers.dart';

/// Shown while a claim request is pending, or after it's rejected. Once a
/// claim is approved, the router redirect sends the user to the normal
/// `/provider` dashboard instead (a real provider_profiles row exists by
/// then), so this screen never needs to render an "approved" state itself.
class ProviderClaimStatusScreen extends ConsumerWidget {
  const ProviderClaimStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimStatusAsync = ref.watch(myClaimStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Claim request')),
      body: SafeArea(
        child: claimStatusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text('Something went wrong. Please try again.'),
          ),
          data: (claim) {
            if (claim == null) {
              return const Center(child: Text('No claim request found.'));
            }
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    claim.isPending
                        ? Icons.hourglass_top
                        : Icons.cancel_outlined,
                    size: 48,
                    color: claim.isPending ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    claim.businessName,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    claim.isPending
                        ? "We're reviewing your claim request. We'll notify "
                              'you once it has been approved or rejected.'
                        : (claim.rejectionReason ??
                              'Your claim request was rejected.'),
                    textAlign: TextAlign.center,
                  ),
                  if (claim.isRejected) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/provider/choose'),
                      child: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
