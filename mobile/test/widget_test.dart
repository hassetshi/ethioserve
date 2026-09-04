import 'package:ethioserve/app.dart';
import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_catalog_repository.dart';
import 'fakes/fake_provider_repository.dart';

void main() {
  testWidgets('app boots to the language selection screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const EthioServeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('አማርኛ'), findsOneWidget);
  });

  testWidgets(
    'selecting a language with no session lands on free discovery home',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
          ],
          child: const EthioServeApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Discovery (search, categories) is reachable without logging in...
      expect(find.text('What service do you need?'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      // ...but account-only affordances are replaced by a single Log in entry.
      expect(find.text('Log in'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsNothing);
    },
  );

  testWidgets('an already-authenticated user lands on home with categories', (
    tester,
  ) async {
    final fakeAuth = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'test-user-id',
        role: UserRole.customer,
        languageCode: 'en',
        isActive: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const EthioServeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('What service do you need?'), findsOneWidget);
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Electrical'), findsOneWidget);
  });

  testWidgets('an authenticated provider lands on the provider dashboard', (
    tester,
  ) async {
    final fakeAuth = FakeAuthRepository(
      initialUser: const AppUser(
        id: 'test-provider-id',
        role: UserRole.provider,
        languageCode: 'en',
        isActive: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(myProviderId: 'provider-1'),
          ),
        ],
        child: const EthioServeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Provider Dashboard'), findsOneWidget);
    expect(find.text('Test Provider'), findsOneWidget);
  });
}
