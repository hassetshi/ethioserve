// Regression test for a real router bug found via live testing: once a
// locale is chosen, `/language` and `/language/change` were missing from
// the anonymous-user allowlist in app_router.dart's redirect, so an
// anonymous user backing into `/language` (after the language_selection_
// screen.dart first-launch push fix) - or tapping Home's language icon -
// was bounced to a login wall instead of seeing language selection.
import 'package:ethioserve/app.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/onboarding/presentation/language_selection_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_catalog_repository.dart';
import '../helpers/shared_preferences_override.dart';

void main() {
  testWidgets(
    'an anonymous user backing into /language sees language selection, not a login wall',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
            await fakeSharedPreferencesOverride(),
          ],
          child: const EthioServeApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('What service do you need?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);

      // Back from Home (still anonymous) should reveal /language, not
      // bounce to Login.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('Enter your phone number'), findsNothing);
    },
  );

  testWidgets(
    'an anonymous user can reach "change language" from Home without hitting a login wall',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
            await fakeSharedPreferencesOverride(),
          ],
          child: const EthioServeApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Language'));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('Enter your phone number'), findsNothing);
    },
  );
}
