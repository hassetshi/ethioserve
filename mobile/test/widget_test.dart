import 'package:ethioserve/app.dart';
import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_repository.dart';
import 'fakes/fake_catalog_repository.dart';

void main() {
  testWidgets('app boots to the language selection screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
        child: const EthioServeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('አማርኛ'), findsOneWidget);
  });

  testWidgets('selecting a language with no session redirects to login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
        child: const EthioServeApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your phone number'), findsOneWidget);
  });

  testWidgets('an already-authenticated user lands on home with categories', (tester) async {
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
}
