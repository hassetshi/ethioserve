import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/auth/presentation/otp_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../helpers/router_test_harness.dart';

void main() {
  testWidgets(
    'redirectTo null (plain login entry): success pops onto Home, nothing further pushed',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const Text('home')),
          GoRoute(path: '/login', builder: (_, _) => const Text('login')),
          GoRoute(
            path: '/otp',
            builder: (_, state) =>
                OtpVerificationScreen(phone: state.extra! as String),
          ),
        ],
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );

      router.push('/login');
      await tester.pumpAndSettle();
      router.push('/otp', extra: '+251912345678');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('login'), findsNothing);
      expect(find.byType(OtpVerificationScreen), findsNothing);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets(
    'redirectTo set (paywall entry): success pops onto the prior browse screen then pushes the target',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/providers/x',
            builder: (_, _) => const Text('provider-profile'),
          ),
          GoRoute(path: '/login', builder: (_, _) => const Text('login')),
          GoRoute(
            path: '/otp',
            builder: (_, state) => OtpVerificationScreen(
              phone: state.extra! as String,
              redirectTo: state.uri.queryParameters['redirect'],
            ),
          ),
          GoRoute(
            path: '/providers/x/book',
            builder: (_, _) => const Text('booking-form'),
          ),
        ],
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
      );

      router.push('/providers/x');
      await tester.pumpAndSettle();
      router.push('/login');
      await tester.pumpAndSettle();
      router.push(
        '/otp?redirect=${Uri.encodeComponent('/providers/x/book')}',
        extra: '+251912345678',
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Landed on the originally-protected destination, not Home.
      expect(find.text('booking-form'), findsOneWidget);
      expect(find.text('login'), findsNothing);
      expect(find.byType(OtpVerificationScreen), findsNothing);

      // Back from the destination reveals the browse trail from before the
      // login wall - not Login or OTP, which are gone from history.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('provider-profile'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(router.canPop(), isFalse);
    },
  );
}
