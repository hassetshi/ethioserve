import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'provider_providers.dart';

class ProvidersForServiceScreen extends ConsumerWidget {
  const ProvidersForServiceScreen({required this.serviceId, super.key});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = ref.watch(providersForServiceProvider(serviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: providersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Something went wrong. Please try again.')),
        data: (providers) {
          if (providers.isEmpty) {
            return const Center(
              child: Text('No verified providers offer this service yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final provider = providers[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.storefront)),
                title: Text(provider.businessName),
                subtitle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})'),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/providers/${provider.providerId}'),
              );
            },
          );
        },
      ),
    );
  }
}
