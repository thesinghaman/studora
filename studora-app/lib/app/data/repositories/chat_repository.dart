import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/enums.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/models/message_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/providers/chat_provider.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class ChatRepository {
  final ChatProvider _provider = Get.put(ChatProvider());
  final AppwriteService _appwrite = Get.find<AppwriteService>();
  final _deletedConversationController = StreamController<String>.broadcast();

  Stream<String> get onConversationDeleted =>
      _deletedConversationController.stream;

  Future<List<ConversationModel>> getConversationsForUser(String userId) async {
    final documents = await _provider.findConversationsByUser(userId);

    return documents
        .where(
          (doc) =>
              !(doc.data['deletedBy'] as List<dynamic>? ?? []).contains(userId),
        )
        .map((doc) => ConversationModel.fromJson(doc.data, doc.$id))
        .toList();
  }

  Future<Map<String, List<String>>> uploadChatImages(List<File> images) async {
    final List<String> imageFileIds = [];
    final List<String> imageUrls = [];
    try {
      for (final image in images) {

        final uploadedFile = await _provider.uploadImage(image);
        final fileId = uploadedFile.$id;
        imageFileIds.add(fileId);

        final imageUrl = _provider.getImageView(fileId);
        imageUrls.add(imageUrl);
      }
      return {'imageFileIds': imageFileIds, 'imageUrls': imageUrls};
    } catch (e) {
      LoggerService.logError('ChatRepository', 'uploadChatImages', e);
      rethrow;
    }
  }


  Future<ConversationModel?> findExistingConversation(
    String currentUserId,
    String otherUserId,
  ) async {

    final userConversations = await _provider.findConversationsByUser(
      currentUserId,
    );

    final existingConvo = userConversations.where((doc) {
      final participants = List<String>.from(doc.data['participants']);

      if (!participants.contains(otherUserId)) {
        return false;
      }
      return true;
    }).toList();
    if (existingConvo.isNotEmpty) {

      return ConversationModel.fromJson(
        existingConvo.first.data,
        existingConvo.first.$id,
      );
    }

    return null;
  }

  Future<List<MessageModel>> getMessages(
    String conversationId,
    String currentUserId,
  ) async {
    return await _provider.getMessages(conversationId, currentUserId);
  }
  Future<models.Execution> sendMessage({
    String? conversationId,
    required String senderId,
    String? text,
    required List<String> participants,
    List<String>? imageUrls,
    List<String>? imageFileIds,
    MessageType? messageType,
    Map<String, String>? participantNames,
    Map<String, String?>? participantAvatars,
    dynamic relatedItem,
  }) async {
    final body = jsonEncode({
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'participants': participants,
      'imageUrls': imageUrls,
      'imageFileIds': imageFileIds,
      'messageType': messageType?.name,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'relatedItem': relatedItem is RelatedItem ? relatedItem.toMap() : null,
    });
    try {
      final execution = await _appwrite.functions.createExecution(
        functionId: AppConstants.createMessageFunctionId,
        body: body,
        method: ExecutionMethod.pOST,
      );
      return execution;
    } catch (e) {
      rethrow;
    }
  }
  Future<void> markMessagesAsRead(
    String conversationId,
    String currentUserId,
  ) async {

    if (conversationId.isEmpty) return;
    try {
      final body = jsonEncode({
        'conversationId': conversationId,
        'userId': currentUserId,
      });
      await _appwrite.functions.createExecution(
        functionId: AppConstants.markMessagesAsReadFunctionId,
        body: body,
        method: ExecutionMethod.pOST,
      );
    } catch (e) {
      LoggerService.logError(
        'ChatRepository',
        'markAllMessagesAsRead',
        "Failed to execute mark-all-as-read: $e",
      );
    }
  }
  Future<void> deleteConversations(
    List<String> conversationIds,
    String userId,
  ) async {
    try {
      await _appwrite.functions.createExecution(
        functionId: AppConstants.deleteConversationsFunctionId,
        body: jsonEncode({
          'conversationIds': conversationIds,
          'userId': userId,
        }),
        method: ExecutionMethod.pOST,
      );

      for (final id in conversationIds) {
        _deletedConversationController.add(id);
      }
    } catch (e) {
      LoggerService.logError('ChatRepository', 'deleteConversations', e);
      rethrow;
    }
  }
  void dispose() {
    _deletedConversationController.close();
  }

  Future<ConversationModel> getConversationById(String conversationId) async {
    final doc = await _provider.getConversationById(conversationId);
    return ConversationModel.fromJson(doc.data, doc.$id);
  }
  Future<void> updateConversationsOnAdUpdate(
    String itemId,
    String newTitle,
    String? newImageUrl,
  ) {
    return _provider.updateConversationsOnAdUpdate(
      itemId,
      newTitle,
      newImageUrl,
    );
  }
}
