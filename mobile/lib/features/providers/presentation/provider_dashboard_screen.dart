import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../notifications/presentation/notification_bell.dart';
import 'provider_providers.dart';

/// Earnings and subscription management (spec section 12) land in Phase 12
/// once payments exist. Booking requests are wired up as of Phase 6.
class ProviderDashboardScreen extends ConsumerWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProviderIdAsync = ref.watch(myProviderIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          const NotificationBell(),
          IconButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: myProviderIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (providerId) {
          if (providerId == null) {
            return const Center(child: Text('No provider profile found.'));
          }
          return _DashboardBody(providerId: providerId);
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(providerDetailProvider(providerId));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('Something went wrong. Please try again.')),
      data: (provider) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () =>
                context.push('/provider/bookings', extra: providerId),
            icon: const Icon(Icons.list_alt),
            label: const Text('Booking Requests'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/providers/$providerId'),
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('View public profile'),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                provider.isVerified ? Icons.verified : Icons.hourglass_top,
                color: provider.isVerified ? Colors.blue : Colors.orange,
              ),
              title: Text(provider.businessName),
              subtitle: Text(_statusLabel(provider.verificationStatus)),
              trailing: TextButton(
                onPressed: () =>
                    context.push('/provider/verification', extra: providerId),
                child: const Text('Verification'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services offered',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push('/provider/services/add', extra: providerId),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          if (provider.services.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No services added yet.'),
            )
          else
            ...provider.services.map(
              (service) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(service.nameEn),
                trailing: Text(service.pricingType),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'verified' => 'Verified',
    'rejected' => 'Verification rejected',
    'suspended' => 'Account suspended',
    _ => 'Verification pending',
  };
}
