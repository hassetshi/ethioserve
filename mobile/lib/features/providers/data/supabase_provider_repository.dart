import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/provider_detail.dart';
import '../domain/provider_repository.dart';
import '../domain/provider_summary.dart';

class SupabaseProviderRepository implements ProviderRepository {
  SupabaseProviderRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<ProviderDetail> getProviderDetail(String providerId) async {
    try {
      final profileRow = await _client
          .from('provider_profiles')
          .select('*, cities(name_en, name_am)')
          .eq('id', providerId)
          .single();

      final serviceRows = await _client
          .from('provider_services')
          .select('min_price, max_price, pricing_type, services(id, name_en, name_am)')
          .eq('provider_id', providerId);

      final photoRows = await _client
          .from('provider_photos')
          .select('storage_path')
          .eq('provider_id', providerId)
          .order('display_order');

      final photoUrls = (photoRows as List)
          .map((row) => _client.storage
              .from('provider-photos')
              .getPublicUrl(row['storage_path'] as String))
          .toList();

      return ProviderDetail.fromJson(
        profileRow,
        services: (serviceRows as List)
            .map((row) => ProviderOfferedService.fromJson(row as Map<String, dynamic>))
            .toList(),
        photoUrls: photoUrls,
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('getProviderDetail failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<ProviderSummary>> listProvidersForService(
    String serviceId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc('search_providers', params: {
        'p_service_id': serviceId,
        'p_limit': limit,
        'p_offset': offset,
      });
      return (rows as List)
          .map((row) => ProviderSummary.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('listProvidersForService failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
