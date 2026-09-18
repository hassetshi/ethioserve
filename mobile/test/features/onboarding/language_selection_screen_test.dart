import 'dart:async';

import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/domain/auth_repository.dart';
import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/onboarding/presentation/language_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/router_test_harness.dart';
import '../../helpers/shared_preferences_override.dart';

/// Never emits until [emit] is called - simulates `currentUserProvider`
/// staying in `AsyncLoading` for a while after language selection, the
/// exact race language_selection_screen.dart's `_select` guards against.
class _DelayedAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> watchCurrentUser() => _controller.stream;

  void emit(AppUser? user) => _controller.add(user);

  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<AppUser> verifyOtp({required String phone, required String code}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

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

  testWidgets(
    'waits for the first auth-state value before navigating, instead of '
    'racing a still-loading currentUserProvider',
    (tester) async {
      final authRepo = _DelayedAuthRepository();
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/language',
        routes: [
          GoRoute(
            path: '/language',
            builder: (_, _) => const LanguageSelectionScreen(),
          ),
          GoRoute(path: '/', builder: (_, _) => const Text('resolved-home')),
        ],
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          await fakeSharedPreferencesOverride(),
        ],
      );

      await tester.tap(find.text('English'));
      await tester.pump();

      // currentUserProvider is still loading (authRepo hasn't emitted) -
      // the push must not have happened yet.
      expect(find.byType(LanguageSelectionScreen), findsOneWidget);
      expect(find.text('resolved-home'), findsNothing);

      authRepo.emit(null);
      await tester.pumpAndSettle();

      // Now that auth resolved, the push happens - and /language is still
      // underneath it in history.
      expect(find.text('resolved-home'), findsOneWidget);
      expect(router.canPop(), isTrue);
    },
  );
}
