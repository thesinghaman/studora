class CollegeModel {
  final String id;
  final String name;
  final String emailDomain;
  final String? city;
  final String? state;
  final String country;
  final String? logoFileId;
  final String? logoUrl;
  final bool isActive;
  CollegeModel({
    required this.id,
    required this.name,
    required this.emailDomain,
    this.city,
    this.state,
    required this.country,
    this.logoFileId,
    this.logoUrl,
    this.isActive = true,
  });
  factory CollegeModel.fromJson(Map<String, dynamic> json, String documentId) {
    return CollegeModel(
      id: documentId,
      name: json['name'] as String,
      emailDomain: json['emailDomain'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'Unknown',
      logoFileId: json['logoFileId'] as String?,
      logoUrl: json['logoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emailDomain': emailDomain,
      'city': city,
      'state': state,
      'country': country,
      'logoFileId': logoFileId,
      'logoUrl': logoUrl,
      'isActive': isActive,
    };
  }
}
