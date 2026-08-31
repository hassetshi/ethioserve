import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/language_selection_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

/// Route table for the customer app. Provider-only and admin-only routes are
/// added in Phase 4/10 respectively, each gated by `users.role` — never by a
/// client-trusted flag (spec section 31: "Do not trust client-side values
/// for: user role").
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
