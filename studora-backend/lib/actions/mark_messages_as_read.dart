import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/chat_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> markMessagesAsRead(dynamic context, Client client, Map<String, dynamic> body) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);

  // 1. Input Validation
  final request = MarkMessagesAsReadRequest.fromMap(body);

  // Security Check: Ensure the user is the one making the request
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];
  if (requestingUserId != null && requestingUserId != request.userId) {
    throw UnauthorizedError('User ID mismatch. You cannot mark messages as read for another user.');
  }

  // 2. Find unread messages sent by others
  final messageList = await databases.listDocuments(
    databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
    collectionId: Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
    queries: [
      Query.equal('conversationId', request.conversationId),
      Query.notEqual('status', 'read'),
      Query.notEqual('senderId', request.userId),
    ],
  );

  // 3. Filter by permission
  final readerPermission = 'read("user:${request.userId}")';
  final messagesToUpdate = messageList.documents.where((doc) {
    return doc.$permissions.contains(readerPermission);
  }).toList();

  // 4. Update Conversation Unread Count
  try {
    final conversation = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      documentId: request.conversationId,
    );

    Map<String, dynamic> unreadCounts = {};
    try {
      unreadCounts = jsonDecode(conversation.data['unreadCounts'] ?? '{}');
    } catch (_) {}

    bool needsCountUpdate = (unreadCounts[request.userId] ?? 0) != 0;
    if (needsCountUpdate) {
      unreadCounts[request.userId] = 0;
      await databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: request.conversationId,
        data: {'unreadCounts': jsonEncode(unreadCounts)},
      );
    }
  } catch (e) {
    logger.error('Failed to update conversation unread count', e);
    // Continue to update messages
  }

  // 5. Update Messages Status
  final futures = <Future>[];
  for (final msg in messagesToUpdate) {
    futures.add(databases.updateDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
      documentId: msg.$id,
      data: {'status': 'read'},
    ));
  }

  if (futures.isNotEmpty) {
    try {
      await Future.wait(futures);
      logger.info('Updated ${messagesToUpdate.length} messages and reset count for ${request.userId}');
    } catch (e) {
      logger.error('Failed to update some messages', e);
      throw AppError(message: 'Failed to update message status', statusCode: 500);
    }
  } else {
    logger.info('No updates needed for ${request.userId}');
  }

  return response.success({
    'updatedCount': messagesToUpdate.length,
    'message': 'Processed read status for ${messagesToUpdate.length} messages.'
  });
}
