import 'package:ethioserve/features/onboarding/presentation/language_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/router_test_harness.dart';
import '../../helpers/shared_preferences_override.dart';

void main() {
  testWidgets(
    'first-launch: picking a language pushes past /language, and Back returns to it',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/language',
        routes: [
          GoRoute(
            path: '/language',
            builder: (_, _) => const LanguageSelectionScreen(),
          ),
          // Stands in for wherever the real router's redirect resolves '/'
          // to (Home or a role home) - this isolated test router has no
          // redirect logic of its own.
          GoRoute(path: '/', builder: (_, _) => const Text('resolved-home')),
        ],
        overrides: [await fakeSharedPreferencesOverride()],
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('resolved-home'), findsOneWidget);
      expect(router.canPop(), isTrue);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('resolved-home'), findsNothing);
    },
  );

  testWidgets('first-launch mode shows no AppBar', (tester) async {
    await pumpTestRouter(
      tester,
      initialLocation: '/language',
      routes: [
        GoRoute(
          path: '/language',
          builder: (_, _) => const LanguageSelectionScreen(),
        ),
      ],
      overrides: [await fakeSharedPreferencesOverride()],
    );

    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets(
    'change-language mode (reached via push) shows an AppBar with a back arrow',
    (tester) async {
      await pumpTestRouter(
        tester,
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/language/change'),
                child: const Text('Change language'),
              ),
            ),
          ),
          GoRoute(
            path: '/language/change',
            builder: (_, _) =>
                LanguageSelectionScreen(onLanguageSelected: () {}),
          ),
        ],
        overrides: [await fakeSharedPreferencesOverride()],
      );

      await tester.tap(find.text('Change language'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    },
  );
}
