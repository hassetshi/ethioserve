import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/otp',
          builder: (_, state) => Text('otp-for-${state.extra}'),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('an invalid phone number shows an error and does not navigate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: wrap(),
      ),
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid Ethiopian phone number.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets(
    'a valid phone number navigates to OTP with the normalized number',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: wrap(),
        ),
      );

      await tester.enterText(find.byType(TextField), '0912345678');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('otp-for-+251912345678'), findsOneWidget);
    },
  );
}
