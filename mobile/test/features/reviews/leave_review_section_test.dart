import 'package:ethioserve/features/reviews/presentation/leave_review_section.dart';
import 'package:ethioserve/features/reviews/presentation/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_review_repository.dart';

void main() {
  testWidgets('submitting a review shows it back as "your review"', (tester) async {
    final fakeRepo = FakeReviewRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [reviewRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: Scaffold(
            body: LeaveReviewSection(bookingId: 'booking-1', providerId: 'provider-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leave a review'), findsOneWidget);

    // Default rating is 5 stars; submit without changing it.
    await tester.enterText(find.byType(TextField), 'Great service');
    await tester.tap(find.text('Submit review'));
    await tester.pumpAndSettle();

    expect(find.text('Your review'), findsOneWidget);
    expect(find.text('Great service'), findsOneWidget);
    expect(fakeRepo.reviews.single.rating, 5);
  });
}
