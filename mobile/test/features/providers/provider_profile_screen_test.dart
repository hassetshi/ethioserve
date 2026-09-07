import 'package:ethioserve/features/providers/presentation/provider_profile_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:ethioserve/features/reviews/presentation/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_provider_repository.dart';
import '../../fakes/fake_review_repository.dart';

void main() {
  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/providers/provider-1',
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) => ProviderProfileScreen(
            providerId: state.pathParameters['providerId']!,
          ),
        ),
        GoRoute(
          path: '/providers/:providerId/book',
          builder: (_, state) =>
              Text('book-${state.pathParameters['providerId']}'),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('shows business name, rating, and a working Book button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(),
          ),
          reviewRepositoryProvider.overrideWithValue(FakeReviewRepository()),
        ],
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.text('No reviews yet.'), findsOneWidget);

    await tester.tap(find.text('Book'));
    await tester.pumpAndSettle();

    expect(find.text('book-provider-1'), findsOneWidget);
  });
}
