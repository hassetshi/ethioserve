import 'package:ethioserve/features/subscriptions/domain/subscription_plan.dart';
import 'package:ethioserve/features/subscriptions/presentation/subscription_plan_screen.dart';
import 'package:ethioserve/features/subscriptions/presentation/subscription_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_subscription_repository.dart';
import '../../helpers/router_test_harness.dart';

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

  testWidgets('a free launch-offer plan needs no Stripe price to subscribe', (
    tester,
  ) async {
    final fakeRepo = FakeSubscriptionRepository(
      plans: const [
        SubscriptionPlan(plan: 'free', priceUsd: 0, interval: 'month'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [subscriptionRepositoryProvider.overrideWithValue(fakeRepo)],
        child: const MaterialApp(
          home: SubscriptionPlanScreen(providerId: 'provider-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Launch offer'), findsOneWidget);
    expect(find.text('Free for a limited time'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Subscribe'));
    await tester.pumpAndSettle();

    expect(fakeRepo.mySubscription, isNotNull);
    expect(fakeRepo.mySubscription!.plan, 'free');
  });

  testWidgets(
    'after subscribing, maybePop actually pops when there is a screen underneath',
    (tester) async {
      final fakeRepo = FakeSubscriptionRepository();
      await pumpTestRouter(
        tester,
        initialLocation: '/placeholder',
        routes: [
          // Stands in for Choose-Path (or Profile) in the real app: pushed
          // once, stays in history.
          GoRoute(
            path: '/placeholder',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/form'),
                child: const Text('placeholder'),
              ),
            ),
          ),
          // Stands in for the provider registration form: reaches Subscribe
          // via pushReplacement (the fix), not push/go, so it is itself
          // removed from history while /placeholder underneath survives.
          GoRoute(
            path: '/form',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pushReplacement('/subscribe'),
                child: const Text('form'),
              ),
            ),
          ),
          GoRoute(
            path: '/subscribe',
            builder: (_, _) =>
                const SubscriptionPlanScreen(providerId: 'provider-1'),
          ),
        ],
        overrides: [subscriptionRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      await tester.tap(find.text('placeholder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Subscribe').first);
      await tester.pumpAndSettle();

      expect(fakeRepo.mySubscription, isNotNull);
      expect(find.byType(SubscriptionPlanScreen), findsNothing);
      expect(find.text('placeholder'), findsOneWidget);
    },
  );
}
