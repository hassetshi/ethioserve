import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'review_providers.dart';

/// Shown on Booking Details when the customer's booking is completed.
/// Renders nothing if they've already reviewed it (server is still the
/// real authority — this just avoids showing a form that would be rejected).
class LeaveReviewSection extends ConsumerStatefulWidget {
  const LeaveReviewSection({required this.bookingId, required this.providerId, super.key});

  final String bookingId;
  final String providerId;

  @override
  ConsumerState<LeaveReviewSection> createState() => _LeaveReviewSectionState();
}

class _LeaveReviewSectionState extends ConsumerState<LeaveReviewSection> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            bookingId: widget.bookingId,
            providerId: widget.providerId,
            rating: _rating,
            comment: _commentController.text.trim().isEmpty
                ? null
                : _commentController.text.trim(),
          );
      ref.invalidate(myReviewForBookingProvider(widget.bookingId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewAsync = ref.watch(myReviewForBookingProvider(widget.bookingId));

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (existing) {
        if (existing != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your review', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _StarRow(rating: existing.rating),
                  if (existing.comment != null) Text(existing.comment!),
                  if (existing.providerResponse != null) ...[
                    const SizedBox(height: 8),
                    Text('Provider response: ${existing.providerResponse}'),
                  ],
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Leave a review', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => _rating = starValue),
                      icon: Icon(
                        starValue <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(hintText: 'Comment (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit review'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        ),
      ),
    );
  }
}
