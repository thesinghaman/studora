import 'dart:io';
import 'package:hive/hive.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
part 'message_model.g.dart';
@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String conversationId;
  @HiveField(2)
  final String senderId;
  @HiveField(3)
  final String? text;
  @HiveField(4)
  final MessageType type;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  MessageStatus status;
  @HiveField(7)
  final List<String>? imageFileIds;
  @HiveField(8)
  final List<String>? imageUrls;
  @HiveField(9)
  final List<String>? localImagePaths;

  List<File>? get localImageFiles =>
      localImagePaths?.map((path) => File(path)).toList();
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.text,
    this.imageFileIds,
    this.imageUrls,
    this.localImagePaths,
    required this.type,
    required this.timestamp,
    required this.status,
  }) : assert(
         type == MessageType.text
             ? text != null && text.isNotEmpty
             : (imageFileIds != null && imageFileIds.isNotEmpty) ||
                   (imageUrls != null && imageUrls.isNotEmpty) ||
                   (localImagePaths != null && localImagePaths.isNotEmpty),
         'A message must have content (text, urls, or local paths).',
       );
  factory MessageModel.fromJson(Map<String, dynamic> json, String documentId) {
    MessageType messageType = MessageType.text;
    if (json['messageType'] == 'image') {
      messageType = MessageType.image;
    }
    MessageStatus messageStatus = MessageStatus.sent;
    if (json['status'] != null) {
      try {
        messageStatus = MessageStatus.values.firstWhere(
          (e) => e.name == json['status'],
        );
      } catch (e) {
        messageStatus = MessageStatus.sent;
      }
    }
    final utcTimestamp = json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String? ?? '')
        : null;
    return MessageModel(
      id: documentId,
      conversationId: json['conversationId'] as String? ?? 'unknown_convo',
      senderId: json['senderId'] as String? ?? 'unknown_sender',
      text: json['text'] as String?,
      imageFileIds: json['imageFileIds'] != null
          ? List<String>.from(json['imageFileIds'])
          : null,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : null,
      localImagePaths: null,
      type: messageType,
      timestamp: utcTimestamp?.toLocal() ?? DateTime.now(),
      status: messageStatus,
    );
  }
  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    List<String>? imageFileIds,
    List<String>? imageUrls,
    List<String>? localImagePaths,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageFileIds: imageFileIds ?? this.imageFileIds,
      imageUrls: imageUrls ?? this.imageUrls,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
