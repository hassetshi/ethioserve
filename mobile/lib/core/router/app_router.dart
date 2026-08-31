import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/catalog/presentation/category_detail_screen.dart';
import '../../features/home/presentation/admin_blocked_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/language_selection_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/providers/presentation/provider_profile_screen.dart';
import '../../features/providers/presentation/providers_for_service_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../providers/locale_provider.dart';

/// Bridges Riverpod state changes into go_router's `refreshListenable`, so
/// the declarative [redirect] below re-runs whenever locale or auth state
/// changes (not just on explicit navigation).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(localeProvider, (_, _) => notifyListeners());
    ref.listen(currentUserProvider, (_, _) => notifyListeners());
  }
}

/// Single source of truth for "where should this user be." Every route
/// decision (language not chosen, not logged in, admin on the customer app)
/// is decided here, not scattered across individual screens (spec section
/// 31: role/auth state drives access, never a screen's own assumption).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final hasLocale = ref.read(localeProvider) != null;
      final path = state.matchedLocation;

      if (!hasLocale) {
        return path == '/language' ? null : '/language';
      }

      if (path == '/otp' && state.extra is! String) {
        // Reached directly (deep link, browser back/forward) without a
        // phone number to verify against.
        return '/login';
      }

      // Only touches the auth provider (and therefore the Supabase client)
      // once locale is chosen — keeps the pre-auth screens usable even
      // before Supabase is initialized.
      final userAsync = ref.read(currentUserProvider);

      if (userAsync.isLoading) {
        // Waiting on the first auth-state event; stay put (splash shows a
        // spinner) rather than guessing.
        return null;
      }

      final user = userAsync.valueOrNull;
      final isAuthRoute = path == '/login' || path == '/otp';

      if (user == null) {
        if (path == '/' || !isAuthRoute) return '/login';
        return null;
      }

      // Logged in past this point.
      if (path == '/' || path == '/language' || isAuthRoute) {
        return user.role == UserRole.admin ? '/admin-blocked' : '/home';
      }

      if (user.role == UserRole.admin && path != '/admin-blocked') {
        return '/admin-blocked';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) =>
            OtpVerificationScreen(phone: state.extra! as String),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin-blocked',
        builder: (context, state) => const AdminBlockedScreen(),
      ),
      GoRoute(
        path: '/categories/:categoryId',
        builder: (context, state) => CategoryDetailScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/services/:serviceId/providers',
        builder: (context, state) => ProvidersForServiceScreen(
          serviceId: state.pathParameters['serviceId']!,
        ),
      ),
      GoRoute(
        path: '/providers/:providerId',
        builder: (context, state) => ProviderProfileScreen(
          providerId: state.pathParameters['providerId']!,
        ),
      ),
    ],
  );
});
