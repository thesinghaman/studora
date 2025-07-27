class CategoryModel {
  final String id;
  final String name;
  final String? iconId;
  final String type;
  final String? parentCategory;
  CategoryModel({
    required this.id,
    required this.name,
    this.iconId,
    required this.type,
    this.parentCategory,
  });
  factory CategoryModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CategoryModel(
      id: documentId,
      name: json['name'] as String,
      iconId: json['iconId'] as String?,
      type: json['type'] as String? ?? 'sale',
      parentCategory: json['parentCategory'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'iconId': iconId,
      'type': type,
      'parentCategory': parentCategory,
    };
  }
}
