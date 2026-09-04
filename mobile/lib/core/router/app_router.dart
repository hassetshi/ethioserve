import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_search/presentation/ai_search_screen.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/bookings/presentation/booking_confirmation_screen.dart';
import '../../features/bookings/presentation/booking_details_screen.dart';
import '../../features/bookings/presentation/booking_request_screen.dart';
import '../../features/bookings/presentation/bookings_list_screen.dart';
import '../../features/bookings/presentation/provider_booking_requests_screen.dart';
import '../../features/catalog/presentation/category_detail_screen.dart';
import '../../features/catalog/presentation/search_screen.dart';
import '../../features/home/presentation/admin_blocked_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/language_selection_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/providers/presentation/add_provider_service_screen.dart';
import '../../features/providers/presentation/provider_dashboard_screen.dart';
import '../../features/providers/presentation/provider_profile_screen.dart';
import '../../features/providers/presentation/provider_registration_screen.dart';
import '../../features/providers/presentation/provider_search_results_screen.dart';
import '../../features/providers/presentation/provider_verification_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/subscriptions/presentation/subscription_plan_screen.dart';
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

/// Routes a logged-out customer can reach: free discovery (search/AI-search/
/// categories/provider profiles). Booking, account, and provider/admin
/// surfaces are not in this list, so they fall through to the login gate.
bool _isPublicDiscoveryRoute(String path) {
  const publicExact = {'/home', '/search', '/ai-search'};
  if (publicExact.contains(path)) return true;
  if (path.startsWith('/categories/')) return true;
  if (path.startsWith('/services/')) return true;
  // Provider profile view (e.g. /providers/abc123), but not the booking
  // sub-route (/providers/abc123/book), which stays login-gated.
  return RegExp(r'^/providers/[^/]+$').hasMatch(path);
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
        // Anonymous customers land on free discovery, not a login wall.
        if (path == '/') return '/home';
        if (isAuthRoute || _isPublicDiscoveryRoute(path)) return null;
        return '/login?redirect=${Uri.encodeComponent(path)}';
      }

      // Logged in past this point.
      if (path == '/' || path == '/language' || isAuthRoute) {
        return switch (user.role) {
          UserRole.admin => '/admin-blocked',
          UserRole.provider => '/provider',
          UserRole.customer => '/home',
        };
      }

      if (user.role == UserRole.admin && path != '/admin-blocked') {
        return '/admin-blocked';
      }

      if (user.role == UserRole.provider && path == '/provider/register') {
        // Already a provider — nothing to register.
        return '/provider';
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
        builder: (context, state) => OtpVerificationScreen(
          phone: state.extra! as String,
          redirectTo: state.uri.queryParameters['redirect'],
        ),
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
        path: '/categories/:categoryId/providers',
        builder: (context, state) => ProviderSearchResultsScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/services/:serviceId/providers',
        builder: (context, state) => ProviderSearchResultsScreen(
          serviceId: state.pathParameters['serviceId']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/ai-search',
        builder: (context, state) => const AiSearchScreen(),
      ),
      GoRoute(
        path: '/providers/:providerId',
        builder: (context, state) => ProviderProfileScreen(
          providerId: state.pathParameters['providerId']!,
        ),
      ),
      GoRoute(
        path: '/provider/register',
        builder: (context, state) => const ProviderRegistrationScreen(),
      ),
      GoRoute(
        path: '/provider',
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: '/provider/subscribe',
        builder: (context, state) => SubscriptionPlanScreen(
          providerId: state.uri.queryParameters['providerId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/provider/services/add',
        builder: (context, state) =>
            AddProviderServiceScreen(providerId: state.extra! as String),
      ),
      GoRoute(
        path: '/provider/verification',
        builder: (context, state) =>
            ProviderVerificationScreen(providerId: state.extra! as String),
      ),
      GoRoute(
        path: '/providers/:providerId/book',
        builder: (context, state) => BookingRequestScreen(
          providerId: state.pathParameters['providerId']!,
        ),
      ),
      GoRoute(
        path: '/bookings',
        builder: (context, state) => const BookingsListScreen(),
      ),
      GoRoute(
        path: '/bookings/:bookingId',
        builder: (context, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/bookings/:bookingId/confirmation',
        builder: (context, state) => BookingConfirmationScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/provider/bookings',
        builder: (context, state) =>
            ProviderBookingRequestsScreen(providerId: state.extra! as String),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/bookings/:bookingId/chat',
        builder: (context, state) =>
            ChatScreen(bookingId: state.pathParameters['bookingId']!),
      ),
    ],
  );
});
