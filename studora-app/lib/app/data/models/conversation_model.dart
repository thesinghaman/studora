import 'dart:convert';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/services/logger_service.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String? lastMessageSnippet;
  final DateTime lastMessageTimestamp;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCounts;
  final List<String>? deletedBy;
  final List<String> visibleTo;
  final List<RelatedItem> relatedItems;
  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessageSnippet,
    required this.lastMessageTimestamp,
    this.lastMessageSenderId,
    required this.unreadCounts,
    this.deletedBy,
    required this.visibleTo,
    required this.relatedItems,
  });

  String? getDeletionTimestampForUser(String userId) {
    if (deletedBy == null) return null;
    for (final recordStr in deletedBy!) {
      try {
        final record = jsonDecode(recordStr) as Map<String, dynamic>;
        if (record['userId'] == userId) {
          return record['deletedAt'] as String?;
        }
      } catch (e) {
        LoggerService.logError(
          "ConversationModel",
          "getDeletionTimestampForUser",
          e.toString(),
        );
      }
    }
    return null;
  }

  bool isDeletedByUser(String userId) {
    return getDeletionTimestampForUser(userId) != null;
  }

  factory ConversationModel.fromJson(
    Map<String, dynamic> json,
    String documentId,
  ) {
    Map<String, T> parseJsonString<T>(dynamic data) {
      if (data is String && data.isNotEmpty) {
        try {
          return Map<String, T>.from(jsonDecode(data) as Map);
        } catch (e) {
          LoggerService.logError(
            "ConversationModel",
            "_parseJsonString",
            "Failed to decode JSON string: $data. Error: $e",
          );
          return {};
        }
      } else if (data is Map) {
        return Map<String, T>.from(data);
      }
      return {};
    }

    List<RelatedItem> parseRelatedItems() {
      List<RelatedItem> items = [];

      if (json['relatedItems'] is List) {
        final itemsList = json['relatedItems'] as List;
        for (var itemData in itemsList) {
          try {
            if (itemData is String) {
              items.add(RelatedItem.fromJson(itemData));
            } else if (itemData is Map) {
              items.add(RelatedItem.fromMap(itemData.cast<String, dynamic>()));
            }
          } catch (e) {
            LoggerService.logError(
              "ConversationModel",
              "_parseRelatedItems",
              "Failed to parse a related item. Data: $itemData, Error: $e",
            );
          }
        }
      } else if (json.containsKey('relatedItemId') &&
          json['relatedItemId'] != null) {
        final participants = List<String>.from(
          json['participants'] as List? ?? [],
        );
        final itemOwner = participants.firstWhere(
          (p) => p != json['lastMessageSenderId'],
          orElse: () => '',
        );
        items.add(
          RelatedItem(
            itemId: json['relatedItemId'] as String,
            itemType: json['itemType'] as String? ?? 'ItemModel',
            ownerId: itemOwner,
            title: json['itemTitle'] as String? ?? 'Untitled Item',
            imageUrl: json['itemImageUrl'] as String?,

            createdAt:
                DateTime.tryParse(
                  json['lastMessageTimestamp'] as String? ?? '',
                ) ??
                DateTime.now(),
          ),
        );
      }

      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return items;
    }

    return ConversationModel(
      id: documentId,
      participants: List<String>.from(json['participants'] as List? ?? []),
      participantNames: parseJsonString<String>(json['participantNames']),
      participantAvatars: parseJsonString<String?>(json['participantAvatars']),
      unreadCounts: parseJsonString<int>(json['unreadCounts']),
      lastMessageSnippet: json['lastMessageSnippet'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.tryParse(json['lastMessageTimestamp'] as String? ?? '') ??
                DateTime.now()
          : DateTime.now(),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      deletedBy: json['deletedBy'] != null
          ? List<String>.from(json['deletedBy'])
          : null,

      visibleTo: List<String>.from(
        json['visibleTo'] as List? ?? json['participants'] as List? ?? [],
      ),

      relatedItems: parseRelatedItems(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'participantNames': jsonEncode(participantNames),
      'participantAvatars': jsonEncode(participantAvatars),
      'lastMessageSnippet': lastMessageSnippet,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': jsonEncode(unreadCounts),
      'deletedBy': deletedBy,
      'visibleTo': visibleTo,
      'relatedItems': relatedItems.map((item) => item.toMap()).toList(),
    };
  }
}
