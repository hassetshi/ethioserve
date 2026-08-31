import 'package:ethioserve/features/auth/domain/app_user.dart';
import 'package:ethioserve/features/auth/domain/auth_repository.dart';

/// Test double so widget tests never touch the real Supabase client.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;

  @override
  Stream<AppUser?> watchCurrentUser() => Stream.value(_user);

  @override
  Future<AppUser?> getCurrentUser() async => _user;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<AppUser> verifyOtp({required String phone, required String code}) async {
    _user = const AppUser(
      id: 'test-user-id',
      role: UserRole.customer,
      languageCode: 'en',
      isActive: true,
    );
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}
