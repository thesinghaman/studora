import 'auth_dtos.dart';

class GetPublicListingsRequest extends RequestDto {
  final String? listingType;
  final String? collegeId;
  final List<String>? categoryIds;
  final String? searchQuery;
  final int limit;
  final int offset;
  final String sortBy;
  final num? minPrice;
  final num? maxPrice;
  final String? startDate;
  final String? endDate;

  GetPublicListingsRequest({
    this.listingType,
    this.collegeId,
    this.categoryIds,
    this.searchQuery,
    this.limit = 15,
    this.offset = 0,
    this.sortBy = 'date_desc',
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
  });

  factory GetPublicListingsRequest.fromMap(Map<String, dynamic> map) {
    return GetPublicListingsRequest(
      listingType: map['listingType'],
      collegeId: map['collegeId'],
      categoryIds: map['categoryIds'] != null
          ? List<String>.from(map['categoryIds'])
          : null,
      searchQuery: map['searchQuery'],
      limit: map['limit'] ?? 15,
      offset: map['offset'] ?? 0,
      sortBy: map['sortBy'] ?? 'date_desc',
      minPrice: map['minPrice'],
      maxPrice: map['maxPrice'],
      startDate: map['startDate'],
      endDate: map['endDate'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'listingType': listingType,
        'collegeId': collegeId,
        'categoryIds': categoryIds,
        'searchQuery': searchQuery,
        'limit': limit,
        'offset': offset,
        'sortBy': sortBy,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'startDate': startDate,
        'endDate': endDate,
      };

  @override
  void validate() {}
}
