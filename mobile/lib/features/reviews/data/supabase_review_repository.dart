import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AppAuthException('You need to be logged in.');
    return id;
  }

  @override
  Future<List<Review>> getReviewsForProvider(String providerId) async {
    try {
      final rows = await _client
          .from('reviews')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);
      return rows.map(Review.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getReviewsForProvider failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Review?> getMyReviewForBooking(String bookingId) async {
    try {
      final row = await _client
          .from('reviews')
          .select()
          .eq('booking_id', bookingId)
          .eq('customer_id', _requireUserId)
          .maybeSingle();
      return row == null ? null : Review.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyReviewForBooking failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<Review> submitReview({
    required String bookingId,
    required String providerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final row = await _client
          .from('reviews')
          .insert({
            'booking_id': bookingId,
            'customer_id': _requireUserId,
            'provider_id': providerId,
            'rating': rating,
            'comment': comment,
          })
          .select()
          .single();
      return Review.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('submitReview failed', error: e, stackTrace: st);
      if (e.code == 'P0001') throw ValidationException(e.message);
      throw const NetworkException();
    }
  }

  @override
  Future<void> respondToReview(String reviewId, String response) async {
    try {
      await _client
          .from('reviews')
          .update({'provider_response': response})
          .eq('id', reviewId);
    } on PostgrestException catch (e, st) {
      AppLogger.error('respondToReview failed', error: e, stackTrace: st);
      if (e.code == 'P0001') throw ValidationException(e.message);
      throw const NetworkException();
    }
  }
}
