import 'dart:convert';
class RelatedItem {
  final String itemId;
  final String itemType;
  final String ownerId;
  final String title;
  final String? imageUrl;
  final DateTime createdAt;
  RelatedItem({
    required this.itemId,
    required this.itemType,
    required this.ownerId,
    required this.title,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'ownerId': ownerId,
      'title': title,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RelatedItem.fromMap(Map<String, dynamic> map) {
    return RelatedItem(
      itemId: map['itemId'] as String? ?? '',
      itemType: map['itemType'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory RelatedItem.fromJson(String source) =>
      RelatedItem.fromMap(json.decode(source) as Map<String, dynamic>);
  @override
  String toString() {
    return 'RelatedItem(itemId: $itemId, itemType: $itemType, ownerId: $ownerId, title: $title, imageUrl: $imageUrl, createdAt: $createdAt)';
  }
}
