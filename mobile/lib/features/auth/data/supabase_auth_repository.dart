import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      if (event.session == null) return null;
      return getCurrentUser();
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final row = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (row == null) return null;
      return AppUser.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error(
        'Failed to load current user row',
        error: e,
        stackTrace: st,
      );
      throw const NetworkException();
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException catch (e, st) {
      AppLogger.error('sendOtp failed', error: e, stackTrace: st);
      throw AppAuthException(_mapAuthError(e));
    }
  }

  @override
  Future<AppUser> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: code,
      );
      if (response.user == null) {
        throw const AppAuthException(
          'Invalid or expired code. Please try again.',
        );
      }
      final user = await getCurrentUser();
      if (user == null) {
        throw const UnknownAppException(
          debugDetail:
              'public.users row missing after successful OTP verification',
        );
      }
      return user;
    } on AuthException catch (e, st) {
      AppLogger.error('verifyOtp failed', error: e, stackTrace: st);
      throw AppAuthException(_mapAuthError(e));
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('token') && message.contains('expired')) {
      return 'This code has expired. Please request a new one.';
    }
    if (message.contains('invalid') || message.contains('token')) {
      return 'That code isn\'t right. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
