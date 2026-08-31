import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_providers.dart';

class ProviderRegistrationController extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<String?> register({
    required String businessName,
    String? description,
    required String phone,
    String? address,
    required String cityId,
  }) async {
    state = const AsyncLoading();
    String? providerId;
    state = await AsyncValue.guard(() async {
      providerId = await ref.read(providerRepositoryProvider).registerAsProvider(
            businessName: businessName,
            descriptionEn: description,
            phone: phone,
            address: address,
            cityId: cityId,
          );
    });
    if (!state.hasError) {
      ref.invalidate(myProviderIdProvider);
    }
    return state.hasError ? null : providerId;
  }
}

final providerRegistrationControllerProvider =
    AsyncNotifierProvider<ProviderRegistrationController, void>(
  ProviderRegistrationController.new,
);
