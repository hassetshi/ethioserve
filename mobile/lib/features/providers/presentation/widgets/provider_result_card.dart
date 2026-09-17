import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/location_provider.dart';
import '../../domain/provider_summary.dart';

/// One provider result, shared by `ProviderSearchResultsScreen`'s filtered
/// list and AI search's inline results - both need the same call/
/// directions/book actions and the same richer fields (address, phone,
/// open-now), so this exists once instead of twice.
///
/// Directions is gated on `summary.address` being present, not shown
/// unconditionally: `search_providers` doesn't return raw lat/lng (only a
/// computed `distance_km`), and as of this widget only 1 of 74 real
/// provider rows has any address on file at all - the 73 imported DC-area
/// businesses only ever had City/State in their source data, no street
/// address. Directions uses the address as a geocoded text destination
/// (Google Maps resolves it), not coordinates.
class ProviderResultCard extends ConsumerWidget {
  const ProviderResultCard({
    required this.summary,
    required this.onTap,
    super.key,
  });

  final ProviderSummary summary;
  final VoidCallback onTap;

  Future<void> _openDirections(WidgetRef ref) async {
    final origin = await ref.read(locationServiceProvider).getCurrentLocation();
    final destination = Uri.encodeComponent(summary.address!);
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin != null ? '&origin=${origin.latitude},${origin.longitude}' : ''}'
      '&destination=$destination'
      '&travelmode=driving',
    );
    launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.storefront)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.businessName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              summary.reviewCount == 0
                                  ? 'No ratings yet'
                                  : '${summary.rating.toStringAsFixed(1)} (${summary.reviewCount})',
                            ),
                            if (summary.distanceKm != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '${summary.distanceKm!.toStringAsFixed(1)} km',
                              ),
                            ],
                          ],
                        ),
                        if (summary.address != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary.address!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (summary.isOpenNow != null) ...[
                          const SizedBox(height: 4),
                          _OpenStatusChip(isOpen: summary.isOpenNow!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (summary.phone != null)
                    IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () =>
                          launchUrl(Uri(scheme: 'tel', path: summary.phone)),
                    ),
                  if (summary.address != null)
                    IconButton(
                      tooltip: 'Directions',
                      icon: const Icon(Icons.directions_outlined),
                      onPressed: () => _openDirections(ref),
                    ),
                  IconButton(
                    tooltip: 'Book',
                    icon: const Icon(Icons.event_available_outlined),
                    onPressed: () =>
                        context.push('/providers/${summary.providerId}/book'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenStatusChip extends StatelessWidget {
  const _OpenStatusChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Closed',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isOpen ? Colors.green.shade900 : Colors.red.shade900,
        ),
      ),
    );
  }
}
