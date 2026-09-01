class AiSearchResult {
  const AiSearchResult({
    required this.matched,
    this.categoryId,
    this.serviceId,
    this.clarificationQuestion,
  });

  final bool matched;
  final String? categoryId;
  final String? serviceId;
  final String? clarificationQuestion;

  factory AiSearchResult.fromJson(Map<String, dynamic> json) => AiSearchResult(
        matched: json['matched'] as bool,
        categoryId: json['categoryId'] as String?,
        serviceId: json['serviceId'] as String?,
        clarificationQuestion: json['clarificationQuestion'] as String?,
      );
}
