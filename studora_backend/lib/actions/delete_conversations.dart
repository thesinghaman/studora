import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

Future<dynamic> deleteConversations(
    dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);
  final storage = Storage(client);

  final conversationIds = body['conversationIds'];
  final userId = body['userId'];

  if (conversationIds == null || conversationIds is! List || userId == null) {
    return context.res
        .json({'success': false, 'error': 'Missing required fields.'}, 400);
  }

  final chatImagesBucketId =
      Platform.environment['APPWRITE_CHAT_STORAGE_BUCKET_ID'];
  if (chatImagesBucketId == null) {
    context.error(
        'Environment variable APPWRITE_CHAT_STORAGE_BUCKET_ID is not set.');
    return context.res
        .json({'success': false, 'error': 'Server configuration error.'}, 500);
  }

  for (final convoId in conversationIds) {
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

      final otherParticipants = participants.where((p) => p != userId).toList();

      // Reset unread count
      Map<String, dynamic> unreadCounts = {};
      try {
        unreadCounts = jsonDecode(conversation.data['unreadCounts'] ?? '{}');
      } catch (_) {}

      if (unreadCounts.containsKey(userId)) {
        context
            .log('Resetting unread count for user $userId in convo $convoId');
        unreadCounts[userId] = 0;
      }

      // Add deletion record
      bool recordExists = false;
      for (int i = 0; i < deletedBy.length; i++) {
        try {
          final record = jsonDecode(deletedBy[i]);
          if (record['userId'] == userId) {
            deletedBy[i] = jsonEncode({
              'userId': userId,
              'deletedAt': DateTime.now().toIso8601String(),
            });
            recordExists = true;
            break;
          }
        } catch (_) {}
      }

      if (!recordExists) {
        deletedBy.add(jsonEncode({
          'userId': userId,
          'deletedAt': DateTime.now().toIso8601String(),
        }));
      }

      // Remove from visibleTo
      if (visibleTo.contains(userId)) {
        visibleTo.remove(userId);
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
        context.log('Performing final delete for conversation $convoId...');

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
                context.error('Failed to delete image $fileId: $e');
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
        context.log('Permanently deleted conversation $convoId');
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
        context.log('Soft-deleted conversation $convoId for user $userId');
      }
    } catch (e) {
      context.error('Failed to process deletion for conversation $convoId: $e');
    }
  }

  return context.res
      .json({'success': true, 'message': 'Deletion process completed.'});
}
