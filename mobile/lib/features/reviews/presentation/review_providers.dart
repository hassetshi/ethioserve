import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_review_repository.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(Supabase.instance.client);
});

final providerReviewsProvider =
    FutureProvider.autoDispose.family<List<Review>, String>((ref, providerId) {
  return ref.watch(reviewRepositoryProvider).getReviewsForProvider(providerId);
});

final myReviewForBookingProvider =
    FutureProvider.autoDispose.family<Review?, String>((ref, bookingId) {
  return ref.watch(reviewRepositoryProvider).getMyReviewForBooking(bookingId);
});
