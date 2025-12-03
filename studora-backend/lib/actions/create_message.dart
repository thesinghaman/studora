import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import '../utils/appwrite_client.dart';
import 'notify_on_new_message.dart'; // Import for direct call

Future<dynamic> createMessage(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);

  // 1. Input Validation
  final senderId = body['senderId'];
  final participants = body['participants'];
  final text = body['text'];
  final imageUrls = body['imageUrls'];
  final imageFileIds = body['imageFileIds'];
  final messageType = body['messageType'];
  final relatedItem = body['relatedItem'];
  final participantNames = body['participantNames'];
  final participantAvatars = body['participantAvatars'];

  var conversationId = body['conversationId'];

  if (senderId == null ||
      participants == null ||
      participants is! List ||
      participants.length < 2) {
    return context.res
        .json({'success': false, 'error': 'Missing or invalid fields.'}, 400);
  }

  if ((text == null || text.isEmpty) &&
      (imageUrls == null || (imageUrls as List).isEmpty)) {
    return context.res.json(
        {'success': false, 'error': 'Message must contain text or images.'},
        400);
  }

  participants.sort();
  final recipientId = participants.firstWhere((p) => p != senderId, orElse: () => null);

  // 2. Find Existing Conversation
  if (conversationId == null) {
    try {
      final queries = participants.map((id) => Query.contains('participants', id)).toList();
      final response = await databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        queries: queries,
      );

      final exactMatch = response.documents.cast<Document?>().firstWhere((doc) {
        if (doc == null) return false;
        final docParticipants = List<String>.from(doc.data['participants'])..sort();
        final reqParticipants = List<String>.from(participants)..sort();
        
        if (docParticipants.length != reqParticipants.length) return false;
        for (int i = 0; i < docParticipants.length; i++) {
          if (docParticipants[i] != reqParticipants[i]) return false;
        }
        return true;
      }, orElse: () => null);

      if (exactMatch != null) {
        conversationId = exactMatch.$id;
        context.log('Found existing conversation: $conversationId');
      }
    } catch (e) {
      context.error('Error searching conversation: $e');
    }
  }

  // 3. Check Block Status
  bool isSenderBlocked = false;
  if (recipientId != null) {
    try {
      final recipientDoc = await databases.getDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
        documentId: recipientId,
      );
      final blockedUsers = List<String>.from(recipientDoc.data['blockedUsers'] ?? []);
      isSenderBlocked = blockedUsers.contains(senderId);
    } catch (e) {
      context.error('Could not check block status: $e');
      return context.res.json({'success': false, 'error': 'Could not verify permissions.'}, 500);
    }
  }

  final timestamp = DateTime.now().toIso8601String();
  final snippet = messageType == 'image'
      ? ((imageUrls as List?)?.length ?? 0) > 1
          ? '📷 ${(imageUrls as List).length} Images'
          : '📷 Image'
      : text;

  // 4. Create or Update Conversation
  try {
    if (conversationId != null) {
      // Update existing
      final conversationDoc = await databases.getDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: conversationId,
      );

      var visibleTo = List<String>.from(conversationDoc.data['visibleTo'] ?? []);
      var deletedBy = List<String>.from(conversationDoc.data['deletedBy'] ?? []);
      var permissions = List<String>.from(conversationDoc.$permissions);
      bool permissionsUpdated = false;

      for (var pId in participants) {
        if (!visibleTo.contains(pId)) {
          if (pId == recipientId && isSenderBlocked) continue;

          visibleTo.add(pId);
          // Check if permission exists (simplified check)
          if (!permissions.any((p) => p.contains('user:$pId'))) {
            permissions.add(Permission.read(Role.user(pId)));
            permissions.add(Permission.update(Role.user(pId)));
            permissionsUpdated = true;
          }
        }
      }

      Map<String, dynamic> unreadCounts = {};
      try {
        unreadCounts = jsonDecode(conversationDoc.data['unreadCounts'] ?? '{}');
      } catch (_) {}

      if (!isSenderBlocked && recipientId != null) {
        unreadCounts[recipientId] = (unreadCounts[recipientId] ?? 0) + 1;
      }

      await databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: conversationId,
        data: {
          'lastMessageTimestamp': timestamp,
          'lastMessageSenderId': senderId,
          'lastMessageSnippet': snippet,
          'unreadCounts': jsonEncode(unreadCounts),
          'visibleTo': visibleTo,
          'deletedBy': deletedBy,
        },
        permissions: permissionsUpdated ? permissions : null,
      );

    } else {
      // Create new
      final unreadCounts = {
        senderId: 0,
        if (recipientId != null) recipientId: isSenderBlocked ? 0 : 1,
      };

      final visibleTo = isSenderBlocked ? [senderId] : participants;

      List<String> permissions;
      if (isSenderBlocked) {
        permissions = [
          Permission.read(Role.user(senderId)),
          Permission.update(Role.user(senderId)),
        ];
      } else {
        permissions = (participants as List)
            .expand((id) => [
                  Permission.read(Role.user(id)),
                  Permission.update(Role.user(id)),
                ])
            .toList()
            .cast<String>();
      }

      final newDoc = await databases.createDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: ID.unique(),
        data: {
          'participants': participants,
          'participantNames': jsonEncode(participantNames ?? {}),
          'participantAvatars': jsonEncode(participantAvatars ?? {}),
          'lastMessageTimestamp': timestamp,
          'unreadCounts': jsonEncode(unreadCounts),
          'lastMessageSenderId': senderId,
          'lastMessageSnippet': snippet,
          'relatedItemId': relatedItem?['id'],
          'itemType': relatedItem?['type'],
          'itemTitle': relatedItem?['title'],
          'itemImageUrl': relatedItem?['imageUrl'],
          'deletedBy': [],
          'visibleTo': visibleTo,
        },
        permissions: permissions,
      );
      conversationId = newDoc.$id;
    }
  } catch (e) {
    context.error('Failed conversation update/create: $e');
    return context.res.json(
        {'success': false, 'error': 'Failed to process conversation.'}, 500);
  }

  // 5. Create Message
  try {
    List<String> messagePermissions;
    if (isSenderBlocked) {
      messagePermissions = [
        Permission.read(Role.user(senderId)),
        Permission.update(Role.user(senderId)),
        Permission.delete(Role.user(senderId)),
      ];
    } else {
      messagePermissions = participants.expand((id) => [
        Permission.read(Role.user(id)),
        Permission.update(Role.user(id)),
        Permission.delete(Role.user(id)),
      ]).toList().cast<String>();
    }

    final messageDoc = await databases.createDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_MESSAGES_COLLECTION_ID']!,
      documentId: ID.unique(),
      data: {
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'imageUrls': imageUrls,
        'imageFileIds': imageFileIds,
        'timestamp': timestamp,
        'messageType': messageType,
        'status': 'sent',
      },
      permissions: messagePermissions,
    );

    // 6. Trigger Notification (DIRECT CALL - NO COLD START!)
    if (!isSenderBlocked) {
      try {
        // We call the function directly!
        // Note: We need to pass the context and client.
        // We construct the data payload expected by notifyOnNewMessage
        final notifyData = {
          ...messageDoc.data,
          'participants': participants,
          'senderId': senderId, // Ensure these are present
          'text': text,
          'conversationId': conversationId,
          'messageType': messageType,
        };

        // We don't await this if we want it to be "fire and forget" like before?
        // Actually, in Dart, if we don't await, the container might shut down before it finishes.
        // So we MUST await it. But since it's the same container, it's fast.
        await notifyOnNewMessage(context, client, notifyData);
      } catch (e) {
        context.error('Failed to trigger notification: $e');
        // Don't fail the main request
      }
    }

    return context.res.json({'success': true, 'data': messageDoc.data});
  } catch (e) {
    context.error('Failed to create message: $e');
    return context.res.json({'success': false, 'error': e.toString()}, 500);
  }
}
