class Category {
  const Category({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    this.icon,
    this.image,
  });

  final String id;
  final String nameEn;
  final String nameAm;
  final String? icon;
  final String? image;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        nameEn: json['name_en'] as String,
        nameAm: json['name_am'] as String,
        icon: json['icon'] as String?,
        image: json['image'] as String?,
      );

  /// Picks the display name for [languageCode] ('am' -> Amharic, else English).
  String localizedName(String languageCode) =>
      languageCode == 'am' ? nameAm : nameEn;
}
