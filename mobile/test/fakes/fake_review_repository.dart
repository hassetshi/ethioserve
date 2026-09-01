import 'package:ethioserve/features/reviews/domain/review.dart';
import 'package:ethioserve/features/reviews/domain/review_repository.dart';

class FakeReviewRepository implements ReviewRepository {
  final List<Review> reviews = [];
  Review? myReview;

  @override
  Future<List<Review>> getReviewsForProvider(String providerId) async =>
      reviews;

  @override
  Future<Review?> getMyReviewForBooking(String bookingId) async => myReview;

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    final review = Review(
      id: 'review-1',
      bookingId: bookingId,
      customerId: 'customer-1',
      providerId: providerId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    reviews.add(review);
    myReview = review;
    return review;
  }

  @override
  Future<void> respondToReview(String reviewId, String response) async {
    final index = reviews.indexWhere((r) => r.id == reviewId);
    if (index == -1) return;
    final r = reviews[index];
    reviews[index] = Review(
      id: r.id,
      bookingId: r.bookingId,
      customerId: r.customerId,
      providerId: r.providerId,
      rating: r.rating,
      comment: r.comment,
      providerResponse: response,
      createdAt: r.createdAt,
    );
  }
}
