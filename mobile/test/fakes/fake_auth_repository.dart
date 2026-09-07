import 'dart:async';

import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/domain/auth_repository.dart';

/// Test double so widget tests never touch the real Supabase client.
///
/// Uses a broadcast StreamController (not `Stream.value`) so that
/// `watchCurrentUser()` genuinely re-emits when `_user` changes later (e.g.
/// after `verifyOtp`) to whoever is already subscribed — matching how the
/// real Supabase-backed repository's `onAuthStateChange` behaves. A plain
/// `Stream.value(_user)` captures `_user` once at call time and never
/// reflects later mutations, which silently broke router-driven navigation
/// in tests (the router's redirect logic kept reading a stale "logged out"
/// value after a successful OTP verification).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _user;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<AppUser> verifyOtp({
    required String phone,
    required String code,
  }) async {
    _user = const AppUser(
      id: 'test-user-id',
      role: UserRole.customer,
      languageCode: 'en',
      isActive: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
