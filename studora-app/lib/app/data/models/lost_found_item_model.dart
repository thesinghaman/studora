import 'package:appwrite/models.dart' as appwrite_models;
import 'package:studora/app/shared_components/utils/enums.dart';
class LostFoundItemModel {
  String? id;
  String title;
  String description;
  LostFoundType type;
  String categoryId;
  String? categoryName;
  DateTime dateReported;
  DateTime? dateFoundOrLost;
  String location;
  List<String>? imageUrls;
  String reporterId;
  String reporterName;
  String? reporterCollegeId;
  String? contactInfo;
  String postStatus;
  bool isActive;
  DateTime expiryDate;
  DateTime? createdAt;
  DateTime? updatedAt;
  LostFoundItemModel({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.categoryId,
    this.categoryName,
    required this.dateReported,
    this.dateFoundOrLost,
    required this.location,
    this.imageUrls,
    required this.reporterId,
    required this.reporterName,
    this.reporterCollegeId,
    this.contactInfo,
    this.postStatus = "Active",
    this.isActive = true,
    required this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });
  factory LostFoundItemModel.fromAppwriteDocument(
    appwrite_models.Document doc,
  ) {
    final data = doc.data;
    return LostFoundItemModel(
      id: doc.$id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: LostFoundType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => LostFoundType.lost,
      ),
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String?,
      dateReported: data['dateReported'] != null
          ? DateTime.parse(data['dateReported'] as String)
          : DateTime.now(),
      dateFoundOrLost: data['dateFoundOrLost'] != null
          ? DateTime.parse(data['dateFoundOrLost'] as String)
          : null,
      location: data['location'] as String? ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'] as List<dynamic>)
          : null,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      reporterCollegeId: data['reporterCollegeId'] as String?,
      contactInfo: data['contactInfo'] as String?,
      postStatus: data['postStatus'] as String? ?? 'Active',
      isActive: data['isActive'] as bool? ?? true,
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.parse(doc.$createdAt),
      updatedAt: DateTime.parse(doc.$updatedAt),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      'dateReported': dateReported.toIso8601String(),
      if (dateFoundOrLost != null)
        'dateFoundOrLost': dateFoundOrLost!.toIso8601String(),
      'location': location,
      if (imageUrls != null && imageUrls!.isNotEmpty) 'imageUrls': imageUrls,
      'reporterId': reporterId,
      'reporterName': reporterName,
      if (reporterCollegeId != null) 'reporterCollegeId': reporterCollegeId,
      if (contactInfo != null) 'contactInfo': contactInfo,
      'postStatus': postStatus,
      'isActive': isActive,
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
  LostFoundItemModel copyWith({
    String? id,
    String? title,
    String? description,
    LostFoundType? type,
    String? categoryId,
    String? categoryName,
    DateTime? dateReported,
    DateTime? dateFoundOrLost,
    String? location,
    List<String>? imageUrls,
    String? reporterId,
    String? reporterName,
    String? reporterCollegeId,
    String? contactInfo,
    String? postStatus,
    bool? isActive,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LostFoundItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      dateReported: dateReported ?? this.dateReported,
      dateFoundOrLost: dateFoundOrLost ?? this.dateFoundOrLost,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterCollegeId: reporterCollegeId ?? this.reporterCollegeId,
      contactInfo: contactInfo ?? this.contactInfo,
      postStatus: postStatus ?? this.postStatus,
      isActive: isActive ?? this.isActive,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
