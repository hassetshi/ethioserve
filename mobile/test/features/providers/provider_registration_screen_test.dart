import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_catalog_repository.dart';
import '../../fakes/fake_provider_repository.dart';
import '../../helpers/router_test_harness.dart';
import '../../helpers/shared_preferences_override.dart';

void main() {
  testWidgets(
    'after successful registration, Back returns to what was before the '
    'form, not the just-submitted (non-resubmittable) form itself',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/placeholder',
        routes: [
          GoRoute(
            path: '/placeholder',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/provider/register'),
                child: const Text('Register a new business'),
              ),
            ),
          ),
          GoRoute(
            path: '/provider/register',
            builder: (_, _) => const ProviderRegistrationScreen(),
          ),
          GoRoute(
            path: '/provider/subscribe',
            builder: (_, state) =>
                Text('subscribe-${state.uri.queryParameters['providerId']}'),
          ),
        ],
        overrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(),
          ),
          await fakeSharedPreferencesOverride(),
        ],
      );

      await tester.tap(find.text('Register a new business'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Business name'),
        'Test Biz',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Business phone'),
        '0912345678',
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Addis Ababa').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('subscribe-provider-1'), findsOneWidget);
      expect(find.byType(ProviderRegistrationScreen), findsNothing);

      // pushReplacement, not go: the placeholder is still underneath.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Register a new business'), findsOneWidget);
      expect(find.byType(ProviderRegistrationScreen), findsNothing);
    },
  );
}
