import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/phone_number_validator.dart';
import 'auth_providers.dart';

class LoginController extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Returns the normalized phone number on success (so the caller can pass
  /// it to the OTP screen), or `null` if [rawPhone] is invalid.
  Future<String?> sendOtp(String rawPhone) async {
    final normalized = PhoneNumberValidator.normalize(rawPhone);
    if (normalized == null) return null;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendOtp(normalized),
    );
    return state.hasError ? null : normalized;
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
