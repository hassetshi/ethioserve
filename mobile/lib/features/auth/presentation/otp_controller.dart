import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_user.dart';
import 'auth_providers.dart';

class OtpController extends AsyncNotifier<AppUser?> {
  @override
  AppUser? build() => null;

  Future<bool> verify({required String phone, required String code}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(authRepositoryProvider).verifyOtp(phone: phone, code: code),
    );
    return !state.hasError;
  }

  Future<void> resend(String phone) async {
    await ref.read(authRepositoryProvider).sendOtp(phone);
  }
}

final otpControllerProvider = AsyncNotifierProvider<OtpController, AppUser?>(
  OtpController.new,
);
