class CountryModel {
  final String id;
  final String name;
  final String code;
  final String currencySymbol;
  final bool isActive;
  CountryModel({
    required this.id,
    required this.name,
    required this.code,
    required this.currencySymbol,
    this.isActive = true,
  });
  factory CountryModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CountryModel(
      id: documentId,
      name: json['name'] as String? ?? 'Unknown Country',
      code: json['code'] as String? ?? 'XX',
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'currencySymbol': currencySymbol,
      'isActive': isActive,
    };
  }
}
