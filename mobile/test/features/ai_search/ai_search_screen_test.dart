import 'package:ethioserve/core/providers/location_provider.dart';
import 'package:ethioserve/core/speech/speech_providers.dart';
import 'package:ethioserve/features/ai_search/domain/ai_search_result.dart';
import 'package:ethioserve/features/ai_search/presentation/ai_search_screen.dart';
import 'package:ethioserve/features/ai_search/presentation/ai_service_providers.dart';
import 'package:ethioserve/features/catalog/presentation/catalog_providers.dart';
import 'package:ethioserve/features/providers/domain/provider_summary.dart';
import 'package:ethioserve/features/providers/presentation/provider_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_ai_service.dart';
import '../../fakes/fake_catalog_repository.dart';
import '../../fakes/fake_location_service.dart';
import '../../fakes/fake_provider_repository.dart';
import '../../fakes/fake_speech_to_text_service.dart';
import '../../helpers/shared_preferences_override.dart';

void main() {
  Widget wrap(Widget child, {required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/ai-search', builder: (_, _) => child),
        GoRoute(
          path: '/providers/:providerId',
          builder: (_, state) =>
              Text('provider-${state.pathParameters['providerId']}'),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'a matched service shows matching providers inline, without navigating',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(
              FakeAIService(
                const AiSearchResult(matched: true, serviceId: 'svc-1'),
              ),
            ),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
            providerRepositoryProvider.overrideWithValue(
              FakeProviderRepository(
                searchResults: const [
                  ProviderSummary(
                    providerId: 'provider-1',
                    businessName: 'Addis Plumbing Experts',
                    rating: 4.5,
                    reviewCount: 10,
                    verificationStatus: 'verified',
                    phone: '+12025550123',
                    address: '123 Main St',
                  ),
                ],
              ),
            ),
            locationServiceProvider.overrideWithValue(
              const FakeLocationService(),
            ),
            await fakeSharedPreferencesOverride(),
          ],
          child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I need a plumber');
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      // Still on AI search - the query stays visible and results show below.
      expect(find.text('I need a plumber'), findsOneWidget);
      expect(find.text('Pipe Repair'), findsOneWidget);
      expect(find.text('Addis Plumbing Experts'), findsOneWidget);
    },
  );

  testWidgets(
    'a matched service with no nearby providers shows an empty state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(
              FakeAIService(
                const AiSearchResult(matched: true, serviceId: 'svc-1'),
              ),
            ),
            catalogRepositoryProvider.overrideWithValue(
              FakeCatalogRepository(),
            ),
            providerRepositoryProvider.overrideWithValue(
              FakeProviderRepository(),
            ),
            locationServiceProvider.overrideWithValue(
              const FakeLocationService(),
            ),
            await fakeSharedPreferencesOverride(),
          ],
          child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I need a plumber');
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      expect(
        find.text('No providers found nearby for that yet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping a matched result navigates to its provider profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAIService(
              const AiSearchResult(matched: true, serviceId: 'svc-1'),
            ),
          ),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(
              searchResults: const [
                ProviderSummary(
                  providerId: 'provider-1',
                  businessName: 'Addis Plumbing Experts',
                  rating: 4.5,
                  reviewCount: 10,
                  verificationStatus: 'verified',
                ),
              ],
            ),
          ),
          locationServiceProvider.overrideWithValue(
            const FakeLocationService(),
          ),
          await fakeSharedPreferencesOverride(),
        ],
        child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
      ),
    );

    await tester.enterText(find.byType(TextField), 'I need a plumber');
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Addis Plumbing Experts'));
    await tester.pumpAndSettle();

    expect(find.text('provider-provider-1'), findsOneWidget);
  });

  testWidgets('an unmatched query shows the clarification question', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAIService(
              const AiSearchResult(
                matched: false,
                clarificationQuestion: 'What kind of service do you need?',
              ),
            ),
          ),
          await fakeSharedPreferencesOverride(),
        ],
        child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
      ),
    );

    await tester.enterText(find.byType(TextField), 'help');
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(find.text('What kind of service do you need?'), findsOneWidget);
  });

  testWidgets('tapping the mic transcribes speech and searches with it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAIService(
              const AiSearchResult(matched: true, serviceId: 'svc-1'),
            ),
          ),
          speechToTextServiceProvider.overrideWithValue(
            FakeSpeechToTextService(result: 'I need a plumber'),
          ),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          providerRepositoryProvider.overrideWithValue(
            FakeProviderRepository(
              searchResults: const [
                ProviderSummary(
                  providerId: 'provider-1',
                  businessName: 'Addis Plumbing Experts',
                  rating: 4.5,
                  reviewCount: 10,
                  verificationStatus: 'verified',
                ),
              ],
            ),
          ),
          locationServiceProvider.overrideWithValue(
            const FakeLocationService(),
          ),
          await fakeSharedPreferencesOverride(),
        ],
        child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    // Transcribed speech was used as the search query and results shown.
    expect(find.text('Addis Plumbing Experts'), findsOneWidget);
  });

  testWidgets('an unrecognized voice result shows a helpful message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechToTextServiceProvider.overrideWithValue(
            FakeSpeechToTextService(result: null),
          ),
          await fakeSharedPreferencesOverride(),
        ],
        child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
      ),
    );

    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't hear that"), findsOneWidget);
  });
}
