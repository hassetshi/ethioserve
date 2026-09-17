import 'package:ethioserve/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps a minimal [GoRouter]-backed app for tests that need to exercise
/// real push/pop/pushReplacement navigation between one or more real
/// screens and lightweight placeholder routes, inside a [ProviderScope].
/// Mirrors the ad hoc router built inline in login_screen_test.dart, pulled
/// out because several back-navigation regression tests need the same shape.
/// Always wires up [AppLocalizations] so screens that call
/// `AppLocalizations.of(context)` (e.g. language selection, Home) work
/// without every call site needing to know that.
Future<GoRouter> pumpTestRouter(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initialLocation,
  List<Override> overrides = const [],
}) async {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
