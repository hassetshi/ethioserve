import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../reviews/presentation/provider_reviews_section.dart';
import '../domain/provider_detail.dart';
import 'provider_providers.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final detailAsync = ref.watch(providerDetailProvider(providerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Provider')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (provider) => _ProviderProfileBody(
          provider: provider,
          languageCode: languageCode,
        ),
      ),
      bottomNavigationBar: detailAsync.maybeWhen(
        data: (provider) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: provider.services.isEmpty
                  ? null
                  : () => context.push('/providers/$providerId/book'),
              child: const Text('Book'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _ProviderProfileBody extends ConsumerWidget {
  const _ProviderProfileBody({
    required this.provider,
    required this.languageCode,
  });

  final ProviderDetail provider;
  final String languageCode;

  String? get _description =>
      languageCode == 'am' ? provider.descriptionAm : provider.descriptionEn;

  String? get _cityName =>
      languageCode == 'am' ? provider.cityNameAm : provider.cityNameEn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.photoUrls.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.photoUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  provider.photoUrls[index],
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(
                    width: 220,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                provider.businessName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (provider.isVerified)
              const Icon(Icons.verified, color: Colors.blue),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)',
            ),
            if (_cityName != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 2),
              Text(_cityName!),
            ],
          ],
        ),
        if (_description != null) ...[
          const SizedBox(height: 16),
          Text(_description!),
        ],
        const SizedBox(height: 24),
        Text('Services', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...provider.services.map(
          (service) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(languageCode == 'am' ? service.nameAm : service.nameEn),
            trailing: Text(_formatPrice(service)),
          ),
        ),
        const SizedBox(height: 24),
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ProviderReviewsSection(providerId: provider.id),
      ],
    );
  }

  String _formatPrice(ProviderOfferedService service) {
    return switch (service.pricingType) {
      'quote' => 'By quote',
      'hourly' when service.minPrice != null =>
        '\$${service.minPrice!.toStringAsFixed(0)}/hr',
      'starting_from' when service.minPrice != null =>
        'From \$${service.minPrice!.toStringAsFixed(0)}',
      _ when service.minPrice != null && service.maxPrice != null =>
        '\$${service.minPrice!.toStringAsFixed(0)}–\$${service.maxPrice!.toStringAsFixed(0)}',
      _ when service.minPrice != null =>
        '\$${service.minPrice!.toStringAsFixed(0)}',
      _ => 'Price on request',
    };
  }
}
