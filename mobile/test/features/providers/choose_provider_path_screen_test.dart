import 'package:ethioserve/features/providers/domain/provider_claim_status.dart';
import 'package:ethioserve/features/providers/presentation/choose_provider_path_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_claim_status_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_provider_repository.dart';
import '../../helpers/router_test_harness.dart';

void main() {
  testWidgets(
    'an in-flight claim auto-replaces Choose-Path, and Back skips it (not showing it again)',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/placeholder',
        routes: [
          GoRoute(
            path: '/placeholder',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/provider/choose'),
                child: const Text('Become a provider'),
              ),
            ),
          ),
          GoRoute(
            path: '/provider/choose',
            builder: (_, _) => const ChooseProviderPathScreen(),
          ),
          GoRoute(
            path: '/provider/claim/status',
            builder: (_, _) => const ProviderClaimStatusScreen(),
          ),
        ],
        overrides: [
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(
              myClaimStatus: const ProviderClaimStatus(
                id: 'claim-1',
                providerId: 'provider-1',
                businessName: 'Test Business',
                status: 'pending',
              ),
            ),
          ),
        ],
      );

      await tester.tap(find.text('Become a provider'));
      await tester.pumpAndSettle();

      // Auto-redirected straight to the status screen.
      expect(find.byType(ProviderClaimStatusScreen), findsOneWidget);
      expect(find.byType(ChooseProviderPathScreen), findsNothing);

      // pushReplacement, not go: the placeholder is still underneath.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Become a provider'), findsOneWidget);
      expect(find.byType(ChooseProviderPathScreen), findsNothing);
    },
  );
}
