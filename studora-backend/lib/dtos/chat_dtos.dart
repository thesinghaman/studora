import '../utils/validator.dart';
import '../utils/exceptions.dart';
import 'auth_dtos.dart'; // For RequestDto

class CreateMessageRequest extends RequestDto {
  final String senderId;
  final List<String> participants;
  final String? text;
  final List<String>? imageUrls;
  final List<String>? imageFileIds;
  final String? messageType;
  final Map<String, dynamic>? relatedItem;
  final Map<String, dynamic>? participantNames;
  final Map<String, dynamic>? participantAvatars;
  final String? conversationId;

  CreateMessageRequest({
    required this.senderId,
    required this.participants,
    this.text,
    this.imageUrls,
    this.imageFileIds,
    this.messageType,
    this.relatedItem,
    this.participantNames,
    this.participantAvatars,
    this.conversationId,
  });

  factory CreateMessageRequest.fromMap(Map<String, dynamic> map) {
    final senderId = map['senderId'];
    final participants = map['participants'];
    final text = map['text'];
    final imageUrls = map['imageUrls'];

    final senderIdError = Validator.validateRequired(senderId, 'Sender ID');
    if (senderIdError != null) throw ValidationError(senderIdError);

    if (participants == null || participants is! List || participants.length < 2) {
      throw ValidationError('Participants must be a list of at least 2 user IDs.');
    }

    if ((text == null || text.toString().isEmpty) &&
        (imageUrls == null || (imageUrls as List).isEmpty)) {
      throw ValidationError('Message must contain text or images.');
    }

    return CreateMessageRequest(
      senderId: senderId,
      participants: List<String>.from(participants),
      text: text,
      imageUrls: imageUrls != null ? List<String>.from(imageUrls) : null,
      imageFileIds: map['imageFileIds'] != null ? List<String>.from(map['imageFileIds']) : null,
      messageType: map['messageType'],
      relatedItem: map['relatedItem'],
      participantNames: map['participantNames'],
      participantAvatars: map['participantAvatars'],
      conversationId: map['conversationId'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'participants': participants,
        'text': text,
        'imageUrls': imageUrls,
        'imageFileIds': imageFileIds,
        'messageType': messageType,
        'relatedItem': relatedItem,
        'participantNames': participantNames,
        'participantAvatars': participantAvatars,
        'conversationId': conversationId,
      };

  @override
  void validate() {}
}

class MarkMessagesAsReadRequest extends RequestDto {
  final String conversationId;
  final String userId;

  MarkMessagesAsReadRequest({
    required this.conversationId,
    required this.userId,
  });

  factory MarkMessagesAsReadRequest.fromMap(Map<String, dynamic> map) {
    final conversationId = map['conversationId'];
    final userId = map['userId'];

    final conversationIdError = Validator.validateRequired(conversationId, 'Conversation ID');
    if (conversationIdError != null) throw ValidationError(conversationIdError);

    final userIdError = Validator.validateRequired(userId, 'User ID');
    if (userIdError != null) throw ValidationError(userIdError);

    return MarkMessagesAsReadRequest(
      conversationId: conversationId,
      userId: userId,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'userId': userId,
      };

  @override
  void validate() {}
}

class NotifyOnNewMessageRequest extends RequestDto {
  final String senderId;
  final List<String> participants;
  final String? text;
  final String? conversationId;
  final String? messageType;

  NotifyOnNewMessageRequest({
    required this.senderId,
    required this.participants,
    this.text,
    this.conversationId,
    this.messageType,
  });

  factory NotifyOnNewMessageRequest.fromMap(Map<String, dynamic> map) {
    final senderId = map['senderId'];
    final participants = map['participants'];

    final senderIdError = Validator.validateRequired(senderId, 'Sender ID');
    if (senderIdError != null) throw ValidationError(senderIdError);

    if (participants == null || participants is! List) {
      throw ValidationError('Participants must be a list.');
    }

    return NotifyOnNewMessageRequest(
      senderId: senderId,
      participants: List<String>.from(participants),
      text: map['text'],
      conversationId: map['conversationId'],
      messageType: map['messageType'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'participants': participants,
        'text': text,
        'conversationId': conversationId,
        'messageType': messageType,
      };

  @override
  void validate() {}
}

class UpdateConversationsRequest extends RequestDto {
  final String type;
  final String? itemId;
  final String? newTitle;
  final String? newImageUrl;
  final String? userId;
  final String? newAvatarUrl;

  UpdateConversationsRequest({
    required this.type,
    this.itemId,
    this.newTitle,
    this.newImageUrl,
    this.userId,
    this.newAvatarUrl,
  });

  factory UpdateConversationsRequest.fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    final typeError = Validator.validateRequired(type, 'Update Type');
    if (typeError != null) throw ValidationError(typeError);

    if (type == 'itemUpdate') {
      if (map['itemId'] == null || map['newTitle'] == null) {
        throw ValidationError('Missing fields for itemUpdate: itemId and newTitle.');
      }
    } else if (type == 'avatarUpdate') {
      // Add validation for avatarUpdate if needed
    } else {
      throw ValidationError('Invalid update type received: $type');
    }

    return UpdateConversationsRequest(
      type: type,
      itemId: map['itemId'],
      newTitle: map['newTitle'],
      newImageUrl: map['newImageUrl'],
      userId: map['userId'],
      newAvatarUrl: map['newAvatarUrl'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'itemId': itemId,
        'newTitle': newTitle,
        'newImageUrl': newImageUrl,
        'userId': userId,
        'newAvatarUrl': newAvatarUrl,
      };

  @override
  void validate() {}
}

class DeleteConversationsRequest extends RequestDto {
  final List<String> conversationIds;
  final String userId;

  DeleteConversationsRequest({
    required this.conversationIds,
    required this.userId,
  });

  factory DeleteConversationsRequest.fromMap(Map<String, dynamic> map) {
    final conversationIds = map['conversationIds'];
    final userId = map['userId'];

    if (conversationIds == null || conversationIds is! List) {
      throw ValidationError('conversationIds must be a list.');
    }

    final userIdError = Validator.validateRequired(userId, 'User ID');
    if (userIdError != null) throw ValidationError(userIdError);

    return DeleteConversationsRequest(
      conversationIds: List<String>.from(conversationIds),
      userId: userId,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'conversationIds': conversationIds,
        'userId': userId,
      };

  @override
  void validate() {}
}
