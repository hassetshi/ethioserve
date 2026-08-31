class City {
  const City({required this.id, required this.nameEn, required this.nameAm});

  final String id;
  final String nameEn;
  final String nameAm;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        nameEn: json['name_en'] as String,
        nameAm: json['name_am'] as String,
      );

  String localizedName(String languageCode) =>
      languageCode == 'am' ? nameAm : nameEn;
}
