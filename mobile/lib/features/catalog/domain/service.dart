class Service {
  const Service({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAm,
    this.descriptionEn,
    this.descriptionAm,
  });

  final String id;
  final String categoryId;
  final String nameEn;
  final String nameAm;
  final String? descriptionEn;
  final String? descriptionAm;

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'] as String,
        categoryId: json['category_id'] as String,
        nameEn: json['name_en'] as String,
        nameAm: json['name_am'] as String,
        descriptionEn: json['description_en'] as String?,
        descriptionAm: json['description_am'] as String?,
      );

  String localizedName(String languageCode) =>
      languageCode == 'am' ? nameAm : nameEn;
}
