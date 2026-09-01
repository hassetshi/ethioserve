import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../catalog/presentation/catalog_providers.dart';
import 'provider_providers.dart';

const _ratingOptions = [null, 3.0, 4.0, 4.5];

/// Shared by both the category-browse flow (Phase 3) and the text-search
/// flow (Phase 5) — either arrives here with a [serviceId] or a
/// [categoryId], and the filter controls (city, rating, distance) are the
/// same regardless of how the user got here (spec section 17).
class ProviderSearchResultsScreen extends ConsumerStatefulWidget {
  const ProviderSearchResultsScreen({
    this.serviceId,
    this.categoryId,
    super.key,
  }) : assert(serviceId != null || categoryId != null);

  final String? serviceId;
  final String? categoryId;

  @override
  ConsumerState<ProviderSearchResultsScreen> createState() =>
      _ProviderSearchResultsScreenState();
}

class _ProviderSearchResultsScreenState
    extends ConsumerState<ProviderSearchResultsScreen> {
  String? _cityId;
  double? _minRating;
  double? _lat;
  double? _lng;
  bool _locatingUser = false;

  Future<void> _useMyLocation() async {
    setState(() => _locatingUser = true);
    final location = await ref
        .read(locationServiceProvider)
        .getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _locatingUser = false;
      _lat = location?.latitude;
      _lng = location?.longitude;
    });
    if (location == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't get your location. Check location permissions, or filter by city instead.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider)?.languageCode ?? 'en';
    final citiesAsync = ref.watch(citiesProvider);

    final filters = (
      categoryId: widget.categoryId,
      serviceId: widget.serviceId,
      cityId: _cityId,
      lat: _lat,
      lng: _lng,
      minRating: _minRating,
    );
    final resultsAsync = ref.watch(providerSearchResultsProvider(filters));

    return Scaffold(
      appBar: AppBar(title: const Text('Providers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                citiesAsync.maybeWhen(
                  data: (cities) => DropdownButton<String?>(
                    hint: const Text('City'),
                    value: _cityId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Any city'),
                      ),
                      ...cities.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.localizedName(languageCode)),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _cityId = value),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                DropdownButton<double?>(
                  hint: const Text('Rating'),
                  value: _minRating,
                  items: _ratingOptions
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r == null ? 'Any rating' : '$r+ stars'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _minRating = value),
                ),
                ChoiceChip(
                  label: Text(_lat != null ? 'Near me ✓' : 'Near me'),
                  selected: _lat != null,
                  avatar: _locatingUser
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onSelected: (selected) {
                    if (selected) {
                      _useMyLocation();
                    } else {
                      setState(() {
                        _lat = null;
                        _lng = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('Something went wrong. Please try again.'),
              ),
              data: (providers) {
                if (providers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No verified providers match these filters yet.',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.storefront),
                      ),
                      title: Text(provider.businessName),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                          ),
                          if (provider.distanceKm != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${provider.distanceKm!.toStringAsFixed(1)} km',
                            ),
                          ],
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push('/providers/${provider.providerId}'),
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
