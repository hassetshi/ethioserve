import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/presentation/provider_providers.dart';
import '../domain/review.dart';
import 'review_providers.dart';

/// Shown on a provider's public profile. If the viewer owns this provider
/// profile, unanswered reviews get a "Respond" button — this is the only
/// place spec section 22-adjacent review responses happen, there's no
/// separate admin/dashboard path for it.
class ProviderReviewsSection extends ConsumerWidget {
  const ProviderReviewsSection({required this.providerId, super.key});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(providerReviewsProvider(providerId));
    final myProviderId = ref.watch(myProviderIdProvider).valueOrNull;
    final isProviderView = myProviderId != null && myProviderId == providerId;

    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No reviews yet.'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reviews
              .map(
                (review) => _ReviewTile(
                  review: review,
                  canRespond: isProviderView && review.providerResponse == null,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ReviewTile extends ConsumerStatefulWidget {
  const _ReviewTile({required this.review, required this.canRespond});

  final Review review;
  final bool canRespond;

  @override
  ConsumerState<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends ConsumerState<_ReviewTile> {
  bool _responding = false;

  Future<void> _respond() async {
    final controller = TextEditingController();
    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to this review'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (response == null || response.isEmpty) return;

    setState(() => _responding = true);
    try {
      await ref
          .read(reviewRepositoryProvider)
          .respondToReview(widget.review.id, response);
      ref.invalidate(providerReviewsProvider(widget.review.providerId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
          if (review.comment != null) Text(review.comment!),
          if (review.providerResponse != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Provider: ${review.providerResponse}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          if (widget.canRespond)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _responding ? null : _respond,
                child: const Text('Respond'),
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
}
