import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/catalog/presentation/category_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_catalog_repository.dart';
import '../../helpers/shared_preferences_override.dart';

void main() {
  testWidgets('shows services for the category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          await fakeSharedPreferencesOverride(),
        ],
        child: const MaterialApp(
          home: CategoryDetailScreen(categoryId: 'cat-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plumbing'), findsOneWidget); // app bar title
    expect(find.text('Pipe Repair'), findsOneWidget);
  });
}
