import 'dart:typed_data';

import 'package:ethioserve/features/providers/domain/provider_detail.dart';
import 'package:ethioserve/features/providers/domain/provider_document.dart';
import 'package:ethioserve/features/providers/domain/provider_repository.dart';
import 'package:ethioserve/features/providers/domain/provider_summary.dart';

class FakeProviderRepository implements ProviderRepository {
  FakeProviderRepository({this.myProviderId, this.searchResults = const []});

  String? myProviderId;
  final List<ProviderSummary> searchResults;

  @override
  Future<String?> getMyProviderId() async => myProviderId;

  @override
  Future<ProviderDetail> getProviderDetail(String providerId) async =>
      const ProviderDetail(
        id: 'provider-1',
        businessName: 'Test Provider',
        rating: 4.5,
        reviewCount: 10,
        verificationStatus: 'pending',
        services: [
          ProviderOfferedService(
            serviceId: 'service-1',
            nameEn: 'Pipe Repair',
            nameAm: 'የቧንቧ ጥገና',
            minPrice: 300,
            maxPrice: 800,
            pricingType: 'starting_from',
          ),
        ],
        photoUrls: [],
      );

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
  }) async => searchResults;

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
    myProviderId = 'provider-1';
    return 'provider-1';
  }

  @override
  Future<void> addOfferedService({
    required String providerId,
    required String serviceId,
    double? minPrice,
    double? maxPrice,
    required String pricingType,
  }) async {}

  @override
  Future<List<ProviderDocument>> getMyDocuments(String providerId) async => [];

  @override
  Future<void> uploadVerificationDocument({
    required String providerId,
    required String documentType,
    required Uint8List bytes,
    required String fileExtension,
  }) async {}
}
