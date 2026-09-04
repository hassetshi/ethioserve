import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/home/presentation/home_screen.dart';
import 'package:ethioserve/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_catalog_repository.dart';

void main() {
  Widget wrap(Widget child) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => child),
        GoRoute(
          path: '/services/:serviceId/providers',
          builder: (_, state) =>
              Text('providers-for-service-${state.pathParameters['serviceId']}'),
        ),
        GoRoute(
          path: '/categories/:categoryId/providers',
          builder: (_, state) => Text(
            'providers-for-category-${state.pathParameters['categoryId']}',
          ),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets('tapping the search field does not navigate away', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: wrap(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();

    // Still on Home: the greeting and category grid are still there.
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('typing shows matching category and service suggestions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: wrap(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'p');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // "Plumbing" (category) and "Pipe Repair" (service) both match "p".
    // "Plumbing" also appears as a category grid tile below, so scope to
    // the suggestion ListTile specifically.
    expect(find.widgetWithText(ListTile, 'Plumbing'), findsOneWidget);
    expect(find.text('Pipe Repair'), findsOneWidget);
  });

  testWidgets('selecting a service suggestion navigates to its providers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: wrap(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'pipe');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pipe Repair'));
    await tester.pumpAndSettle();

    expect(find.text('providers-for-service-svc-1'), findsOneWidget);
  });

  testWidgets('selecting a category suggestion navigates to its providers', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: wrap(const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'plumb');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // "Plumbing" also appears as a category grid tile below, so scope the
    // tap to the suggestion ListTile specifically.
    await tester.tap(find.widgetWithText(ListTile, 'Plumbing'));
    await tester.pumpAndSettle();

    expect(find.text('providers-for-category-cat-1'), findsOneWidget);
  });
}
