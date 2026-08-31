import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/provider_detail.dart';
import '../domain/provider_document.dart';
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

  @override
  Future<String?> getMyProviderId() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('provider_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return row?['id'] as String?;
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyProviderId failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<String> registerAsProvider({
    required String businessName,
    String? descriptionEn,
    String? descriptionAm,
    required String phone,
    String? address,
    required String cityId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final providerId = await _client.rpc('register_as_provider', params: {
        'p_business_name': businessName,
        'p_description_en': descriptionEn,
        'p_description_am': descriptionAm,
        'p_phone': phone,
        'p_address': address,
        'p_city_id': cityId,
        'p_latitude': latitude,
        'p_longitude': longitude,
      });
      return providerId as String;
    } on PostgrestException catch (e, st) {
      AppLogger.error('registerAsProvider failed', error: e, stackTrace: st);
      if (e.message.contains('already registered')) {
        throw const ValidationException('You are already registered as a provider.');
      }
      throw const NetworkException();
    }
  }

  @override
  Future<void> addOfferedService({
    required String providerId,
    required String serviceId,
    double? minPrice,
    double? maxPrice,
    required String pricingType,
  }) async {
    try {
      await _client.from('provider_services').insert({
        'provider_id': providerId,
        'service_id': serviceId,
        'min_price': minPrice,
        'max_price': maxPrice,
        'pricing_type': pricingType,
      });
    } on PostgrestException catch (e, st) {
      AppLogger.error('addOfferedService failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<ProviderDocument>> getMyDocuments(String providerId) async {
    try {
      final rows = await _client
          .from('provider_documents')
          .select('id, document_type, verification_status')
          .eq('provider_id', providerId)
          .order('created_at');
      return rows.map(ProviderDocument.fromJson).toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyDocuments failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<void> uploadVerificationDocument({
    required String providerId,
    required String documentType,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path = '$providerId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    try {
      await _client.storage.from('provider-documents').uploadBinary(path, bytes);
      await _client.from('provider_documents').insert({
        'provider_id': providerId,
        'document_type': documentType,
        'storage_path': path,
      });
    } on StorageException catch (e, st) {
      AppLogger.error('uploadVerificationDocument (storage) failed', error: e, stackTrace: st);
      throw const NetworkException();
    } on PostgrestException catch (e, st) {
      AppLogger.error('uploadVerificationDocument (db) failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }
}
