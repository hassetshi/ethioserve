import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import 'catalog_providers.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    final servicesAsync = ref.watch(servicesByCategoryProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (category) => Text(category.localizedName(languageCode)),
          loading: () => const Text(''),
          error: (_, _) => const Text('Category'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => context.push('/categories/$categoryId/providers'),
              child: const Text('View all providers in this category'),
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Something went wrong. Please try again.')),
              data: (services) {
                if (services.isEmpty) {
                  return const Center(child: Text('No services in this category yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return ListTile(
                      title: Text(service.localizedName(languageCode)),
                      subtitle: languageCode == 'am'
                          ? (service.descriptionAm != null ? Text(service.descriptionAm!) : null)
                          : (service.descriptionEn != null ? Text(service.descriptionEn!) : null),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/services/${service.id}/providers'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
