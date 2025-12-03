import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> markMessagesAsRead(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);

  final conversationId = body['conversationId'];
  final userId = body['userId'];

  if (conversationId == null || userId == null) {
    return context.res.json({'success': false, 'error': 'Missing conversationId or userId.'}, 400);
  }

  try {
    // 1. Find unread messages sent by others
    final messageList = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
      queries: [
        Query.equal('conversationId', conversationId),
        Query.notEqual('status', 'read'),
        Query.notEqual('senderId', userId),
      ],
    );

    // 2. Filter by permission (Dart SDK doesn't expose $permissions in Document model easily? 
    // Actually it does: doc.$permissions)
    final readerPermission = 'read("user:$userId")';
    final messagesToUpdate = messageList.documents.where((doc) {
      return doc.$permissions.contains(readerPermission);
    }).toList();

    // 3. Update Conversation Unread Count
    final conversation = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      documentId: conversationId,
    );

    Map<String, dynamic> unreadCounts = {};
    try {
      unreadCounts = jsonDecode(conversation.data['unreadCounts'] ?? '{}');
    } catch (_) {}

    bool needsCountUpdate = (unreadCounts[userId] ?? 0) != 0;
    if (needsCountUpdate) {
      unreadCounts[userId] = 0;
    }

    // 4. Execute Updates
    final futures = <Future>[];

    if (needsCountUpdate) {
      futures.add(databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: conversationId,
        data: {'unreadCounts': jsonEncode(unreadCounts)},
      ));
    }

    for (final msg in messagesToUpdate) {
      futures.add(databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
        documentId: msg.$id,
        data: {'status': 'read'},
      ));
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      context.log('Updated ${messagesToUpdate.length} messages and reset count for $userId');
    } else {
      context.log('No updates needed for $userId');
    }

    return context.res.json({
      'success': true, 
      'message': 'Processed read status for ${messagesToUpdate.length} messages.'
    });

  } catch (e) {
    context.error('Failed to mark messages as read: $e');
    return context.res.json({'success': false, 'error': e.toString()}, 500);
  }
}
