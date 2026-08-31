class ProviderDocument {
  const ProviderDocument({
    required this.id,
    required this.documentType,
    required this.verificationStatus,
  });

  final String id;
  final String documentType;
  final String verificationStatus;

  factory ProviderDocument.fromJson(Map<String, dynamic> json) => ProviderDocument(
        id: json['id'] as String,
        documentType: json['document_type'] as String,
        verificationStatus: json['verification_status'] as String,
      );
}
