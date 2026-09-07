import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
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
    // AsyncValue.guard swallows the exception into state with no logging of
    // its own — found the hard way while diagnosing a real Android network
    // issue that this silence made much harder to track down than it needed
    // to be (see ARCHITECTURE.md's Phase 17 note).
    if (state.hasError) {
      AppLogger.error(
        'sendOtp failed',
        error: state.error,
        stackTrace: state.stackTrace,
      );
    }
    return state.hasError ? null : normalized;
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
