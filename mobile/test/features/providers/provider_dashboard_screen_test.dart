import 'package:ethioserve/features/auth/presentation/auth_providers.dart';
import 'package:ethioserve/features/providers/presentation/provider_dashboard_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_provider_repository.dart';
import '../../helpers/router_test_harness.dart';

void main() {
  testWidgets('tapping Sign out signs out and explicitly navigates to Login, '
      'rather than relying solely on the router\'s reactive redirect', (
    tester,
  ) async {
    await pumpTestRouter(
      tester,
      initialLocation: '/provider',
      routes: [
        GoRoute(
          path: '/provider',
          builder: (_, _) => const ProviderDashboardScreen(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const Text('login')),
      ],
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        providerRepositoryProvider.overrideWithValue(FakeProviderRepository()),
      ],
    );

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });
}
