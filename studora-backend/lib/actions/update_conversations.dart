import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import '../utils/appwrite_client.dart';

Future<dynamic> updateConversations(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);
  final type = body['type'];

  try {
    switch (type) {
      case 'itemUpdate':
        await _handleItemUpdate(context, databases, body);
        return context.res.json({'success': true, 'message': 'Item update processed.'});

      case 'avatarUpdate':
        await _handleAvatarUpdate(context, databases, body);
        return context.res.json({'success': true, 'message': 'Avatar update processed.'});

      default:
        context.error('Invalid update type received: $type');
        return context.res.json({'success': false, 'error': 'Invalid update type.'}, 400);
    }
  } catch (e) {
    context.error('Failed to process update of type \'$type\': $e');
    return context.res.json({'success': false, 'error': e.toString()}, 500);
  }
}

Future<void> _handleItemUpdate(dynamic context, Databases databases, Map<String, dynamic> body) async {
  final itemId = body['itemId'];
  final newTitle = body['newTitle'];
  final newImageUrl = body['newImageUrl'];

  if (itemId == null || newTitle == null) {
    throw Exception('Missing fields for itemUpdate: itemId and newTitle.');
  }

  final documents = await _listAllDocuments(databases, [
    Query.equal('relatedItemId', itemId),
  ]);

  if (documents.isEmpty) {
    context.log('No conversations found for item $itemId.');
    return;
  }

  final updateFutures = documents.map((doc) {
    return databases.updateDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      documentId: doc.$id,
      data: {
        'itemTitle': newTitle,
        'itemImageUrl': newImageUrl ?? doc.data['itemImageUrl'],
      },
    );
  });

  await Future.wait(updateFutures);
  context.log('Updated ${documents.length} conversations for item $itemId.');
}

Future<void> _handleAvatarUpdate(dynamic context, Databases databases, Map<String, dynamic> body) async {
  final userId = body['userId'];
  final newAvatarUrl = body['newAvatarUrl'];

  if (userId == null) {
    throw Exception('Missing field for avatarUpdate: userId.');
  }

  final documents = await _listAllDocuments(databases, [
    Query.equal('participants', userId),
  ]);

  if (documents.isEmpty) {
    context.log('No conversations found for user $userId.');
    return;
  }

  final updateFutures = documents.map((doc) {
    Map<String, dynamic> participantAvatars = {};
    try {
      participantAvatars = jsonDecode(doc.data['participantAvatars'] ?? '{}');
    } catch (_) {}
    
    participantAvatars[userId] = newAvatarUrl;

    return databases.updateDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      documentId: doc.$id,
      data: {
        'participantAvatars': jsonEncode(participantAvatars),
      },
    );
  });

  await Future.wait(updateFutures);
  context.log('Updated avatar in ${documents.length} conversations for user $userId.');
}

Future<List<Document>> _listAllDocuments(Databases databases, List<String> queries) async {
  List<Document> documents = [];
  String? cursor;

  do {
    final currentQueries = [...queries, Query.limit(100)];
    if (cursor != null) {
      currentQueries.add(Query.cursorAfter(cursor));
    }

    final response = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      queries: currentQueries,
    );

    if (response.documents.isNotEmpty) {
      documents.addAll(response.documents);
      cursor = response.documents.last.$id;
    } else {
      cursor = null;
    }
  } while (cursor != null);

  return documents;
}
