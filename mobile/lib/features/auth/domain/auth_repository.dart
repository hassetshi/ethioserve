import 'app_user.dart';

/// Phone-number OTP authentication. No screen or widget calls Supabase
/// directly (spec section 49); everything goes through this interface so
/// the OTP provider/vendor can change without touching UI code.
abstract class AuthRepository {
  /// Emits the current app-level user (role included) whenever auth state
  /// changes, and `null` when signed out.
  Stream<AppUser?> watchCurrentUser();

  Future<AppUser?> getCurrentUser();

  /// Sends an OTP to [phone]. [phone] must already be in E.164 format
  /// (e.g. +12025551234 or +2519XXXXXXXX) — normalization happens in the UI
  /// layer via [PhoneNumberValidator] before this is called.
  Future<void> sendOtp(String phone);

  /// Verifies [code] sent to [phone]. Throws [AppException] on failure.
  Future<AppUser> verifyOtp({required String phone, required String code});

  Future<void> signOut();
}
