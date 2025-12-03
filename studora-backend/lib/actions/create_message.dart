import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/chat_dtos.dart';
import '../utils/exceptions.dart';
import 'notify_on_new_message.dart';

Future<dynamic> createMessage(dynamic context, Client client, Map<String, dynamic> body) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);

  // 1. Input Validation
  final request = CreateMessageRequest.fromMap(body);

  // Security Check: Ensure the sender is the one making the request
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];
  if (requestingUserId != null && requestingUserId != request.senderId) {
    throw UnauthorizedError('Sender ID mismatch. You cannot send messages on behalf of another user.');
  }

  request.participants.sort();
  final recipientId = request.participants.firstWhere((p) => p != request.senderId, orElse: () => '');

  // 2. Find Existing Conversation
  var conversationId = request.conversationId;
  if (conversationId == null) {
    final queries = request.participants.map((id) => Query.contains('participants', id)).toList();
    final docList = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      queries: queries,
    );

    if (docList.total > 0) {
      // Check for exact match
      final exactMatch = docList.documents.cast<Document?>().firstWhere((doc) {
        if (doc == null) return false;
        final docParticipants = List<String>.from(doc.data['participants'])..sort();
        final reqParticipants = List<String>.from(request.participants)..sort();
        
        if (docParticipants.length != reqParticipants.length) return false;
        for (int i = 0; i < docParticipants.length; i++) {
          if (docParticipants[i] != reqParticipants[i]) return false;
        }
        return true;
      }, orElse: () => null);

      if (exactMatch != null) {
        conversationId = exactMatch.$id;
        logger.info('Found existing conversation: $conversationId');
      }
    }
  }

  // 3. Check Block Status
  bool isSenderBlocked = false;
  if (recipientId.isNotEmpty) {
    try {
      final recipientDoc = await databases.getDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
        documentId: recipientId,
      );
      final blockedUsers = List<String>.from(recipientDoc.data['blockedUsers'] ?? []);
      isSenderBlocked = blockedUsers.contains(request.senderId);
    } catch (e) {
      logger.error('Could not check block status', e);
      // Fail safe: assume not blocked or throw? Let's throw to be safe.
      throw AppError(message: 'Could not verify permissions', statusCode: 500);
    }
  }

  final timestamp = DateTime.now().toIso8601String();
  final snippet = request.messageType == 'image'
      ? ((request.imageUrls?.length ?? 0) > 1
          ? '📷 ${request.imageUrls!.length} Images'
          : '📷 Image')
      : request.text;

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

      for (var pId in request.participants) {
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

      if (!isSenderBlocked && recipientId.isNotEmpty) {
        unreadCounts[recipientId] = (unreadCounts[recipientId] ?? 0) + 1;
      }

      await databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: conversationId,
        data: {
          'lastMessageTimestamp': timestamp,
          'lastMessageSenderId': request.senderId,
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
        request.senderId: 0,
        if (recipientId.isNotEmpty) recipientId: isSenderBlocked ? 0 : 1,
      };

      final visibleTo = isSenderBlocked ? [request.senderId] : request.participants;

      List<String> permissions;
      if (isSenderBlocked) {
        permissions = [
          Permission.read(Role.user(request.senderId)),
          Permission.update(Role.user(request.senderId)),
        ];
      } else {
        permissions = request.participants
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
          'participants': request.participants,
          'participantNames': jsonEncode(request.participantNames ?? {}),
          'participantAvatars': jsonEncode(request.participantAvatars ?? {}),
          'lastMessageTimestamp': timestamp,
          'unreadCounts': jsonEncode(unreadCounts),
          'lastMessageSenderId': request.senderId,
          'lastMessageSnippet': snippet,
          'relatedItemId': request.relatedItem?['id'],
          'itemType': request.relatedItem?['type'],
          'itemTitle': request.relatedItem?['title'],
          'itemImageUrl': request.relatedItem?['imageUrl'],
          'deletedBy': [],
          'visibleTo': visibleTo,
        },
        permissions: permissions,
      );
      conversationId = newDoc.$id;
    }
  } catch (e) {
    logger.error('Failed conversation update/create', e);
    throw AppError(message: 'Failed to process conversation', statusCode: 500);
  }

  // 5. Create Message
  try {
    List<String> messagePermissions;
    if (isSenderBlocked) {
      messagePermissions = [
        Permission.read(Role.user(request.senderId)),
        Permission.update(Role.user(request.senderId)),
        Permission.delete(Role.user(request.senderId)),
      ];
    } else {
      messagePermissions = request.participants.expand((id) => [
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
        'senderId': request.senderId,
        'text': request.text,
        'imageUrls': request.imageUrls,
        'imageFileIds': request.imageFileIds,
        'timestamp': timestamp,
        'messageType': request.messageType,
        'status': 'sent',
      },
      permissions: messagePermissions,
    );

    // 6. Trigger Notification
    if (!isSenderBlocked) {
      try {
        final notifyData = {
          ...messageDoc.data,
          'participants': request.participants,
          'senderId': request.senderId,
          'text': request.text,
          'conversationId': conversationId,
          'messageType': request.messageType,
        };

        await notifyOnNewMessage(context, client, notifyData);
      } catch (e) {
        logger.error('Failed to trigger notification', e);
        // Don't fail the main request
      }
    }

    final result = Map<String, dynamic>.from(messageDoc.data);
    result['\$id'] = messageDoc.$id;
    result['\$createdAt'] = messageDoc.$createdAt;

    return response.success(result);
  } catch (e) {
    logger.error('Failed to create message', e);
    throw AppError(message: 'Failed to send message', statusCode: 500);
  }
}
