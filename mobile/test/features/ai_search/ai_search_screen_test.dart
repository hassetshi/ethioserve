import 'package:ethioserve/features/ai_search/domain/ai_search_result.dart';
import 'package:ethioserve/features/ai_search/presentation/ai_search_screen.dart';
import 'package:ethioserve/features/ai_search/presentation/ai_service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../fakes/fake_ai_service.dart';

void main() {
  Widget wrap(Widget child, {required String initialLocation}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/ai-search', builder: (_, _) => child),
        GoRoute(
          path: '/services/:serviceId/providers',
          builder: (_, state) =>
              Text('providers-for-${state.pathParameters['serviceId']}'),
        ),
        GoRoute(
          path: '/categories/:categoryId/providers',
          builder: (_, state) => Text(
            'providers-for-category-${state.pathParameters['categoryId']}',
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets(
    'a matched service navigates to the providers-for-service screen',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(
              FakeAIService(
                const AiSearchResult(matched: true, serviceId: 'service-1'),
              ),
            ),
          ],
          child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
        ),
      );

      await tester.enterText(find.byType(TextField), 'I need a plumber');
      await tester.tap(find.text('Ask'));
      await tester.pumpAndSettle();

      expect(find.text('providers-for-service-1'), findsOneWidget);
    },
  );

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
        ],
        child: wrap(const AiSearchScreen(), initialLocation: '/ai-search'),
      ),
    );

    await tester.enterText(find.byType(TextField), 'help');
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();

    expect(find.text('What kind of service do you need?'), findsOneWidget);
  });
}
