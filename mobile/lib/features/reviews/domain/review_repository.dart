import 'review.dart';

abstract class ReviewRepository {
  /// Publicly readable (spec: anyone can see a provider's reviews).
  Future<List<Review>> getReviewsForProvider(String providerId);

  /// `null` if the customer hasn't reviewed this booking yet.
  Future<Review?> getMyReviewForBooking(String bookingId);

  /// The server (validate_review_eligibility trigger) is the actual
  /// authority on whether this booking is reviewable — this just submits.
  Future<Review> submitReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
  });

  Future<void> respondToReview(String reviewId, String response);
}
