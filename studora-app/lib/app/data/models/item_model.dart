import 'package:studora/app/shared_components/utils/enums.dart';
class ItemModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final List<String>? imageFileIds;
  final List<String>? imageUrls;
  final String categoryId;
  final String? location;
  final DateTime datePosted;
  final String sellerId;
  final String sellerName;
  final String? sellerProfilePicUrl;
  final String collegeId;
  final bool isRental;
  final ItemCondition? condition;
  final String? rentalTerm;
  final DateTime? availableFrom;
  final String? propertyType;
  final List<String>? amenities;
  bool isFavorite;
  final DateTime expiryDate;
  bool isActive;
  String adStatus;
  final int? viewCount;
  final List<String>? searchTags;
  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.currency = "INR",
    this.imageFileIds,
    this.imageUrls,
    required this.categoryId,
    this.location,
    required this.datePosted,
    required this.sellerId,
    required this.sellerName,
    this.sellerProfilePicUrl,
    required this.collegeId,
    required this.isRental,
    this.condition,
    this.rentalTerm,
    this.availableFrom,
    this.propertyType,
    this.amenities,
    this.isFavorite = false,
    required this.expiryDate,
    this.isActive = true,
    this.adStatus = "Active",
    this.viewCount,
    this.searchTags,
  });
  factory ItemModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ItemModel(
      id: documentId,
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String? ?? 'No Description',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      imageFileIds: json['imageFileIds'] != null
          ? List<String>.from(json['imageFileIds'])
          : null,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : null,
      categoryId: json['categoryId'] as String? ?? 'other',
      location: json['location'] as String?,
      datePosted: json['datePosted'] != null
          ? DateTime.tryParse(json['datePosted'] as String? ?? '') ??
                DateTime.now()
          : DateTime.now(),
      sellerId: json['sellerId'] as String? ?? 'unknown_seller',
      sellerName: json['sellerName'] as String? ?? 'Unknown Seller',
      sellerProfilePicUrl: json['sellerProfilePicUrl'] as String?,
      collegeId: json['collegeId'] as String? ?? 'unknown_college',
      isRental: json['isRental'] as bool? ?? false,
      condition: json['condition'] != null
          ? ItemCondition.values.firstWhere(
              (e) => e.toString().split('.').last == json['condition'],
              orElse: () => ItemCondition.good,
            )
          : null,
      rentalTerm: json['rentalTerm'] as String?,
      availableFrom: json['availableFrom'] != null
          ? DateTime.tryParse(json['availableFrom'] as String? ?? '')
          : null,
      propertyType: json['propertyType'] as String?,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String? ?? '') ??
                DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] as bool? ?? true,
      adStatus: json['adStatus'] as String? ?? 'Active',
      viewCount: json['viewCount'] as int?,
      searchTags: json['searchTags'] != null
          ? List<String>.from(json['searchTags'])
          : null,
    );
  }
  factory ItemModel.fromRealtime(Map<String, dynamic> payload) {
    return ItemModel.fromJson(payload, payload['\$id'] as String);
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'imageFileIds': imageFileIds,
      'imageUrls': imageUrls,
      'categoryId': categoryId,
      'location': location,
      'datePosted': datePosted.toIso8601String(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerProfilePicUrl': sellerProfilePicUrl,
      'collegeId': collegeId,
      'isRental': isRental,
      'condition': condition?.toString().split('.').last,
      'rentalTerm': rentalTerm,
      'availableFrom': availableFrom?.toIso8601String(),
      'propertyType': propertyType,
      'amenities': amenities,
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'adStatus': adStatus,
      'viewCount': viewCount,
      'searchTags': searchTags,
    };
  }
  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currency,
    List<String>? imageFileIds,
    List<String>? imageUrls,
    String? categoryId,
    String? location,
    DateTime? datePosted,
    String? sellerId,
    String? sellerName,
    String? sellerProfilePicUrl,
    String? collegeId,
    bool? isRental,
    ItemCondition? condition,
    String? rentalTerm,
    DateTime? availableFrom,
    String? propertyType,
    List<String>? amenities,
    bool? isFavorite,
    DateTime? expiryDate,
    bool? isActive,
    String? adStatus,
    int? viewCount,
    List<String>? searchTags,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageFileIds: imageFileIds ?? this.imageFileIds,
      imageUrls: imageUrls ?? this.imageUrls,
      categoryId: categoryId ?? this.categoryId,
      location: location ?? this.location,
      datePosted: datePosted ?? this.datePosted,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerProfilePicUrl: sellerProfilePicUrl ?? this.sellerProfilePicUrl,
      collegeId: collegeId ?? this.collegeId,
      isRental: isRental ?? this.isRental,
      condition: condition ?? this.condition,
      rentalTerm: rentalTerm ?? this.rentalTerm,
      availableFrom: availableFrom ?? this.availableFrom,
      propertyType: propertyType ?? this.propertyType,
      amenities: amenities ?? this.amenities,
      isFavorite: isFavorite ?? this.isFavorite,
      expiryDate: expiryDate ?? this.expiryDate,
      isActive: isActive ?? this.isActive,
      adStatus: adStatus ?? this.adStatus,
      viewCount: viewCount ?? this.viewCount,
      searchTags: searchTags ?? this.searchTags,
    );
  }
}
