import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/chat_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> deleteConversations(
    dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);
  final storage = Storage(client);

  // 1. Input Validation
  final request = DeleteConversationsRequest.fromMap(data);

  // Security Check: Ensure the user is the one making the request
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];
  if (requestingUserId != null && requestingUserId != request.userId) {
    throw UnauthorizedError(
        'User ID mismatch. You cannot delete conversations for another user.');
  }

  final chatImagesBucketId =
      Platform.environment['APPWRITE_CHAT_STORAGE_BUCKET_ID'];
  if (chatImagesBucketId == null) {
    throw AppError(
        message:
            'Environment variable APPWRITE_CHAT_STORAGE_BUCKET_ID is not set.');
  }

  for (final convoId in request.conversationIds) {
    try {
      final conversation = await databases.getDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId:
            Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: convoId,
      );

      List<String> deletedBy =
          List<String>.from(conversation.data['deletedBy'] ?? []);
      List<String> visibleTo =
          List<String>.from(conversation.data['visibleTo'] ?? []);
      List<String> participants =
          List<String>.from(conversation.data['participants'] ?? []);

      final otherParticipants =
          participants.where((p) => p != request.userId).toList();

      // Reset unread count
      Map<String, dynamic> unreadCounts = {};
      try {
        unreadCounts = jsonDecode(conversation.data['unreadCounts'] ?? '{}');
      } catch (_) {}

      if (unreadCounts.containsKey(request.userId)) {
        logger.info(
            'Resetting unread count for user ${request.userId} in convo $convoId');
        unreadCounts[request.userId] = 0;
      }

      // Add deletion record
      bool recordExists = false;
      for (int i = 0; i < deletedBy.length; i++) {
        try {
          final record = jsonDecode(deletedBy[i]);
          if (record['userId'] == request.userId) {
            deletedBy[i] = jsonEncode({
              'userId': request.userId,
              'deletedAt': DateTime.now().toIso8601String(),
            });
            recordExists = true;
            break;
          }
        } catch (_) {}
      }

      if (!recordExists) {
        deletedBy.add(jsonEncode({
          'userId': request.userId,
          'deletedAt': DateTime.now().toIso8601String(),
        }));
      }

      // Remove from visibleTo
      if (visibleTo.contains(request.userId)) {
        visibleTo.remove(request.userId);
      }

      // Check for Final Delete
      final deletedUserIds = <String>{};
      for (final recordStr in deletedBy) {
        try {
          final record = jsonDecode(recordStr);
          deletedUserIds.add(record['userId']);
        } catch (_) {}
      }

      final isFinalDelete =
          otherParticipants.every((p) => deletedUserIds.contains(p));

      if (isFinalDelete) {
        logger.info('Performing final delete for conversation $convoId...');

        // Delete messages
        List<Document> messages = [];
        String? cursor;
        do {
          final queries = [
            Query.equal('conversationId', convoId),
            Query.limit(100),
          ];
          if (cursor != null) queries.add(Query.cursorAfter(cursor));

          final res = await databases.listDocuments(
            databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
            collectionId:
                Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
            queries: queries,
          );
          messages.addAll(res.documents);
          if (res.documents.isNotEmpty) {
            cursor = res.documents.last.$id;
          } else {
            cursor = null;
          }
        } while (cursor != null);

        for (final message in messages) {
          final imageFileIds = message.data['imageFileIds'];
          if (imageFileIds != null && imageFileIds is List) {
            for (final fileId in imageFileIds) {
              try {
                await storage.deleteFile(
                    bucketId: chatImagesBucketId, fileId: fileId);
              } catch (e) {
                logger.error('Failed to delete image $fileId', e);
              }
            }
          }
          await databases.deleteDocument(
            databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
            collectionId:
                Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
            documentId: message.$id,
          );
        }

        await databases.deleteDocument(
          databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
          collectionId:
              Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
          documentId: convoId,
        );
        logger.info('Permanently deleted conversation $convoId');
      } else {
        // Soft delete
        final newPermissions = visibleTo
            .expand((id) => [
                  Permission.read(Role.user(id)),
                  Permission.update(Role.user(id)),
                ])
            .toList()
            .cast<String>();

        await databases.updateDocument(
          databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
          collectionId:
              Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
          documentId: convoId,
          data: {
            'deletedBy': deletedBy,
            'visibleTo': visibleTo,
            'unreadCounts': jsonEncode(unreadCounts),
          },
          permissions: newPermissions.toSet().toList(),
        );
        logger.info(
            'Soft-deleted conversation $convoId for user ${request.userId}');
      }
    } catch (e) {
      logger.error('Failed to process deletion for conversation $convoId', e);
      // Continue to next conversation even if one fails
    }
  }

  return response.success({'message': 'Deletion process completed.'});
}
