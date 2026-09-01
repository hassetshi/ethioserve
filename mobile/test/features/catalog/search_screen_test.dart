import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/catalog/presentation/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_catalog_repository.dart';

void main() {
  testWidgets('submitting a query shows matching services', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField), 'pipe');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Pipe Repair'), findsOneWidget);
  });

  testWidgets('no query shows the prompt instead of results', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search for a service, e.g. "plumbing".'), findsOneWidget);
  });
}
