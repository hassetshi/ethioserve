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
    '"Try again" on a rejected claim replaces the status screen, and Back '
    'skips it (returning to what was before it, not the rejected status)',
    (tester) async {
      final router = await pumpTestRouter(
        tester,
        initialLocation: '/placeholder',
        routes: [
          GoRoute(
            path: '/placeholder',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/provider/claim/status'),
                child: const Text('View claim status'),
              ),
            ),
          ),
          GoRoute(
            path: '/provider/claim/status',
            builder: (_, _) => const ProviderClaimStatusScreen(),
          ),
          GoRoute(
            path: '/provider/choose',
            builder: (_, _) => const ChooseProviderPathScreen(),
          ),
        ],
        overrides: [
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(
              myClaimStatus: const ProviderClaimStatus(
                id: 'claim-1',
                providerId: 'provider-1',
                businessName: 'Test Business',
                status: 'rejected',
                rejectionReason: 'Could not verify ownership.',
              ),
            ),
          ),
        ],
      );

      await tester.tap(find.text('View claim status'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(ChooseProviderPathScreen), findsOneWidget);
      expect(find.byType(ProviderClaimStatusScreen), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('View claim status'), findsOneWidget);
      expect(find.byType(ProviderClaimStatusScreen), findsNothing);
    },
  );
}
