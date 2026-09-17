import 'package:ethioserve/features/providers/domain/provider_summary.dart';
import 'package:ethioserve/features/providers/presentation/provider_claim_search_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_claim_status_screen.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_provider_repository.dart';
import '../../helpers/router_test_harness.dart';

void main() {
  testWidgets(
    'submitting a claim replaces the search screen, and Back skips it '
    '(returning to what was before it, and preserving the typed query if '
    'the search screen is reached again)',
    (tester) async {
      final fakeRepo = FakeProviderRepository(
        unclaimedResults: const [
          ProviderSummary(
            providerId: 'provider-1',
            businessName: 'Addis Plumbing Experts',
            rating: 0,
            reviewCount: 0,
            verificationStatus: 'unverified',
          ),
        ],
      );

      final router = await pumpTestRouter(
        tester,
        initialLocation: '/placeholder',
        routes: [
          GoRoute(
            path: '/placeholder',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/provider/claim/search'),
                child: const Text('Claim an existing listing'),
              ),
            ),
          ),
          GoRoute(
            path: '/provider/claim/search',
            builder: (_, _) => const ProviderClaimSearchScreen(),
          ),
          GoRoute(
            path: '/provider/claim/status',
            builder: (_, _) => const ProviderClaimStatusScreen(),
          ),
        ],
        overrides: [providerRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      await tester.tap(find.text('Claim an existing listing'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Addis Plumbing Experts');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(find.text('This is my business'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit request'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderClaimStatusScreen), findsOneWidget);
      expect(find.byType(ProviderClaimSearchScreen), findsNothing);

      // pushReplacement, not go: the placeholder is still underneath, and
      // the just-submitted (now non-resubmittable) search screen is gone.
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Claim an existing listing'), findsOneWidget);
      expect(find.byType(ProviderClaimSearchScreen), findsNothing);
    },
  );
}
