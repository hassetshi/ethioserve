import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_search_results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_catalog_repository.dart';
import '../../fakes/fake_provider_repository.dart';

void main() {
  testWidgets('shows the selected service name in the AppBar title', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ProviderSearchResultsScreen(serviceId: 'svc-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Pipe Repair'), findsOneWidget);
  });

  testWidgets('shows the selected category name in the AppBar title', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(),
          ),
        ],
        child: const MaterialApp(
          home: ProviderSearchResultsScreen(categoryId: 'cat-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Plumbing'), findsOneWidget);
  });
}
