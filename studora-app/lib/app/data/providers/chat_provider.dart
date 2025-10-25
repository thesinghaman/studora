import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/data/models/conversation_model.dart';
import 'package:studora/app/data/models/message_model.dart';
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class ChatProvider {
  final AppwriteService _appwrite = Get.find<AppwriteService>();
  final DatabaseProvider _databaseProvider = Get.find<DatabaseProvider>();

  Future<appwrite_models.Document> createConversation(
    Map<String, dynamic> data,
  ) async {
    return _appwrite.databases.createDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.conversationsCollectionId,
      documentId: ID.unique(),
      data: data,
    );
  }

  Future<List<appwrite_models.Document>> findConversationsByUser(
    String userId,
  ) async {
    final response = await _appwrite.databases.listDocuments(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.conversationsCollectionId,
      queries: [Query.contains('visibleTo', userId)],
    );
    return response.documents;
  }

  Future<appwrite_models.File> uploadImage(File image) async {
    try {
      return await _appwrite.storage.createFile(
        bucketId: AppConstants.itemsImagesBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(
          path: image.path,
          filename: image.path.split('/').last,
        ),
        permissions: [Permission.read(Role.any())],
      );
    } catch (e) {
      LoggerService.logError('ChatProvider', 'uploadImage', e);
      rethrow;
    }
  }

  String getImageView(String fileId) {
    final endpoint = AppwriteService.projectEndpoint;
    final projectId = AppwriteService.projectId;
    final bucketId = AppConstants.itemsImagesBucketId;
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId&mode=public';
  }
  Future<List<MessageModel>> getMessages(
    String conversationId,
    String currentUserId,
  ) async {
    try {

      final convoDoc = await _appwrite.databases.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.conversationsCollectionId,
        documentId: conversationId,
      );
      final conversation = ConversationModel.fromJson(
        convoDoc.data,
        convoDoc.$id,
      );

      final deletionTimestamp = conversation.getDeletionTimestampForUser(
        currentUserId,
      );
      final queries = [
        Query.equal('conversationId', conversationId),
        Query.orderDesc('timestamp'),
      ];

      if (deletionTimestamp != null) {
        queries.add(Query.greaterThan('timestamp', deletionTimestamp));
      }
      final response = await _appwrite.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.messagesCollectionId,
        queries: queries,
      );
      return response.documents
          .map((doc) => MessageModel.fromJson(doc.data, doc.$id))
          .toList();
    } catch (e) {
      LoggerService.logError(
        "ChatProvider",
        "getMessages",
        "Failed to get messages: $e",
      );
      if (e is AppwriteException) {
        throw AppwriteException(e.message, e.code);
      }
      rethrow;
    }
  }
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    await _appwrite.databases.updateDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.messagesCollectionId,
      documentId: messageId,
      data: {'status': status.name},
    );
  }
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final response = await _databaseProvider.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.conversationsCollectionId,
        queries: [
          Query.search('participants', userId),
          Query.orderDesc('lastMessageAt'),
        ],
      );
      final conversations = response.documents
          .map((doc) => ConversationModel.fromJson(doc.data, doc.$id))
          .toList();

      conversations.removeWhere((convo) => convo.isDeletedByUser(userId));
      return conversations;
    } catch (e) {
      LoggerService.logError(
        "ChatProvider",
        "getConversations",
        "Failed to get conversations: $e'",
      );
      rethrow;
    }
  }

  Future<appwrite_models.Document> getConversationById(
    String conversationId,
  ) async {
    return _appwrite.databases.getDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.conversationsCollectionId,
      documentId: conversationId,
    );
  }
  Future<void> updateConversationsOnAdUpdate(
    String itemId,
    String newTitle,
    String? newImageUrl,
  ) async {
    try {


      await _appwrite.functions.createExecution(
        functionId: AppConstants.updateConversationsFunctionId,
        body: jsonEncode({
          'type': 'itemUpdate',
          'itemId': itemId,
          'newTitle': newTitle,
          'newImageUrl': newImageUrl,
        }),
      );
    } on AppwriteException catch (e) {


      LoggerService.logError(
        "ChatProvider",
        "updateConversationsOnAdUpdate",
        'AppwriteException while updating conversations on ad update, $e',
      );
    } catch (e) {
      LoggerService.logError(
        "ChatProvider",
        "updateConversationsOnAdUpdate",
        'Generic exception while updating conversations on ad update, $e',
      );
    }
  }
}
