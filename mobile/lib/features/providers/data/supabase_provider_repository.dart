import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/provider_claim_status.dart';
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
          .select(
            'min_price, max_price, pricing_type, services(id, name_en, name_am)',
          )
          .eq('provider_id', providerId);

      final photoRows = await _client
          .from('provider_photos')
          .select('storage_path')
          .eq('provider_id', providerId)
          .order('display_order');

      final photoUrls = (photoRows as List)
          .map(
            (row) => _client.storage
                .from('provider-photos')
                .getPublicUrl(row['storage_path'] as String),
          )
          .toList();

      return ProviderDetail.fromJson(
        profileRow,
        services: (serviceRows as List)
            .map(
              (row) =>
                  ProviderOfferedService.fromJson(row as Map<String, dynamic>),
            )
            .toList(),
        photoUrls: photoUrls,
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('getProviderDetail failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<List<ProviderSummary>> searchProviders({
    String? categoryId,
    String? serviceId,
    String? cityId,
    double? lat,
    double? lng,
    double radiusKm = 25,
    double? minRating,
    bool verifiedOnly = true,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _client.rpc(
        'search_providers',
        params: {
          'p_category_id': categoryId,
          'p_service_id': serviceId,
          'p_city_id': cityId,
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': radiusKm,
          'p_min_rating': minRating,
          'p_verified_only': verifiedOnly,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return (rows as List)
          .map((row) => ProviderSummary.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error('searchProviders failed', error: e, stackTrace: st);
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
      final providerId = await _client.rpc(
        'register_as_provider',
        params: {
          'p_business_name': businessName,
          'p_description_en': descriptionEn,
          'p_description_am': descriptionAm,
          'p_phone': phone,
          'p_address': address,
          'p_city_id': cityId,
          'p_latitude': latitude,
          'p_longitude': longitude,
        },
      );
      return providerId as String;
    } on PostgrestException catch (e, st) {
      AppLogger.error('registerAsProvider failed', error: e, stackTrace: st);
      if (e.message.contains('already registered')) {
        throw const ValidationException(
          'You are already registered as a provider.',
        );
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
    final path =
        '$providerId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    try {
      await _client.storage
          .from('provider-documents')
          .uploadBinary(path, bytes);
      await _client.from('provider_documents').insert({
        'provider_id': providerId,
        'document_type': documentType,
        'storage_path': path,
      });
    } on StorageException catch (e, st) {
      AppLogger.error(
        'uploadVerificationDocument (storage) failed',
        error: e,
        stackTrace: st,
      );
      throw const NetworkException();
    } on PostgrestException catch (e, st) {
      AppLogger.error(
        'uploadVerificationDocument (db) failed',
        error: e,
        stackTrace: st,
      );
      throw const NetworkException();
    }
  }

  // Plain public read, not an RPC: provider_profiles_select_public already
  // permits reading any is_active row (claimed or not), and ProviderSummary
  // expects a provider_id key, so `id` is aliased to match.
  @override
  Future<List<ProviderSummary>> searchUnclaimedProviders(String query) async {
    try {
      final rows = await _client
          .from('provider_profiles')
          .select(
            'provider_id:id, business_name, description_en, description_am, rating, review_count, verification_status',
          )
          .isFilter('user_id', null)
          .eq('is_active', true)
          .ilike('business_name', '%$query%')
          .limit(20);
      return (rows as List)
          .map((row) => ProviderSummary.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      AppLogger.error(
        'searchUnclaimedProviders failed',
        error: e,
        stackTrace: st,
      );
      throw const NetworkException();
    }
  }

  @override
  Future<ProviderClaimStatus?> getMyClaimStatus() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('provider_claim_requests')
          .select(
            'id, provider_id, status, rejection_reason, provider_profiles(business_name)',
          )
          .eq('requester_user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : ProviderClaimStatus.fromJson(row);
    } on PostgrestException catch (e, st) {
      AppLogger.error('getMyClaimStatus failed', error: e, stackTrace: st);
      throw const NetworkException();
    }
  }

  @override
  Future<void> requestClaim(String providerId) async {
    try {
      await _client.rpc(
        'request_provider_claim',
        params: {'p_provider_id': providerId},
      );
    } on PostgrestException catch (e, st) {
      AppLogger.error('requestClaim failed', error: e, stackTrace: st);
      if (e.message.contains('already has a provider profile')) {
        throw const ValidationException('You already have a provider profile.');
      }
      if (e.message.contains('already been claimed')) {
        throw const ValidationException(
          'This listing has already been claimed.',
        );
      }
      if (e.message.contains('already have a pending claim')) {
        throw const ValidationException(
          'You already submitted a claim for this listing.',
        );
      }
      throw const NetworkException();
    }
  }
}
