import 'package:ethioserve/features/providers/domain/provider_summary.dart';
import 'package:ethioserve/features/providers/presentation/widgets/provider_result_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Call and Directions aren't tapped here - both launch url_launcher, which
// (like geolocator, see fake_location_service.dart) hangs `pumpAndSettle`
// instead of failing fast when its platform channel isn't mocked in a
// widget test. Presence/absence of those buttons is still covered below.
void main() {
  const fullSummary = ProviderSummary(
    providerId: 'provider-1',
    businessName: 'Addis Plumbing Experts',
    rating: 4.5,
    reviewCount: 10,
    verificationStatus: 'verified',
    distanceKm: 2.3,
    phone: '+12025550123',
    address: '123 Main St',
    isOpenNow: true,
  );

  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('shows business name, rating, distance, address, and open chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(ProviderResultCard(summary: fullSummary, onTap: () {})),
    );

    expect(find.text('Addis Plumbing Experts'), findsOneWidget);
    expect(find.text('4.5 (10)'), findsOneWidget);
    expect(find.text('2.3 km'), findsOneWidget);
    expect(find.text('123 Main St'), findsOneWidget);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.byTooltip('Call'), findsOneWidget);
    expect(find.byTooltip('Directions'), findsOneWidget);
    expect(find.byTooltip('Book'), findsOneWidget);
  });

  testWidgets('shows "No ratings yet" when there are no reviews', (
    tester,
  ) async {
    const summary = ProviderSummary(
      providerId: 'provider-1',
      businessName: 'New Provider',
      rating: 0,
      reviewCount: 0,
      verificationStatus: 'verified',
    );

    await tester.pumpWidget(
      wrap(ProviderResultCard(summary: summary, onTap: () {})),
    );

    expect(find.text('No ratings yet'), findsOneWidget);
  });

  testWidgets(
    'hides call/directions buttons and the open chip when the data is missing',
    (tester) async {
      const summary = ProviderSummary(
        providerId: 'provider-1',
        businessName: 'No Contact Info Provider',
        rating: 4.0,
        reviewCount: 3,
        verificationStatus: 'verified',
      );

      await tester.pumpWidget(
        wrap(ProviderResultCard(summary: summary, onTap: () {})),
      );

      expect(find.byTooltip('Call'), findsNothing);
      expect(find.byTooltip('Directions'), findsNothing);
      expect(find.text('Open now'), findsNothing);
      expect(find.text('Closed'), findsNothing);
      // Book has no data dependency - always offered.
      expect(find.byTooltip('Book'), findsOneWidget);
    },
  );

  testWidgets('shows a "Closed" chip when isOpenNow is false', (tester) async {
    const summary = ProviderSummary(
      providerId: 'provider-1',
      businessName: 'Closed Provider',
      rating: 4.0,
      reviewCount: 3,
      verificationStatus: 'verified',
      isOpenNow: false,
    );

    await tester.pumpWidget(
      wrap(ProviderResultCard(summary: summary, onTap: () {})),
    );

    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('tapping the card fires onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        ProviderResultCard(summary: fullSummary, onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.text('Addis Plumbing Experts'));
    expect(tapped, isTrue);
  });

  testWidgets('tapping Book navigates to the booking route', (tester) async {
    final router = GoRouter(
      initialLocation: '/providers/provider-1',
      routes: [
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, _) =>
              ProviderResultCard(summary: fullSummary, onTap: () {}),
        ),
        GoRoute(
          path: '/providers/:providerId/book',
          builder: (_, state) =>
              Text('book-${state.pathParameters['providerId']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );

    await tester.tap(find.byTooltip('Book'));
    await tester.pumpAndSettle();

    expect(find.text('book-provider-1'), findsOneWidget);
  });
}
