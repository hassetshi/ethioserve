import 'package:ethioserve/features/subscriptions/domain/subscription_plan.dart';
import 'package:ethioserve/features/subscriptions/presentation/subscription_plan_screen.dart';
import 'package:ethioserve/features/subscriptions/presentation/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_subscription_repository.dart';

void main() {
  testWidgets('shows real plan prices and lets a provider subscribe', (
    tester,
  ) async {
    final fakeRepo = FakeSubscriptionRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: SubscriptionPlanScreen(providerId: 'provider-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Professional'), findsOneWidget);
    expect(find.text('\$29/month'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('\$79/month'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe').first);
    await tester.pumpAndSettle();

    expect(fakeRepo.mySubscription, isNotNull);
    expect(fakeRepo.mySubscription!.plan, 'professional');
  });

  testWidgets('a plan with no Stripe price yet is not subscribable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(
              plans: const [
                SubscriptionPlan(
                  plan: 'professional',
                  priceUsd: 29,
                  interval: 'month',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: SubscriptionPlanScreen(providerId: 'provider-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not available yet'), findsOneWidget);
  });
}
