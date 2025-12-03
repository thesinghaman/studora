import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/appwrite_client.dart';

Future<dynamic> notifyOnNewMessage(dynamic context, Client client, Map<String, dynamic> data) async {
  final messaging = Messaging(client);
  final databases = Databases(client);

  final senderId = data['senderId'];
  final participants = data['participants'];
  final text = data['text'];
  final conversationId = data['conversationId'];
  final messageType = data['messageType'];

  if (senderId == null || participants == null || participants is! List) {
    context.error('Missing senderId or participants.');
    return context.res.json({
      'success': false,
      'error': 'Missing senderId or participants.'
    }, 400);
  }

  final recipientId = participants.firstWhere((p) => p != senderId, orElse: () => null);

  if (recipientId == null) {
    return context.res.json({
      'success': true,
      'message': 'No recipient to notify.'
    });
  }

  try {
    // Fetch sender's name
    final senderUserDoc = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: senderId,
    );

    final senderName = senderUserDoc.data['name'] ?? 'Someone';

    // Send Push Notification
    final body = messageType == 'image' ? '📷 Sent you an image' : text;
    
    // Note: createPush params might differ slightly in Dart SDK vs Node SDK
    // Checking Dart SDK: createPush(messageId, title, body, {topics, users, targets, data, ...})
    await messaging.createPush(
      messageId: ID.unique(),
      title: 'New Message from $senderName',
      body: body,
      data: {
        'conversationId': conversationId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      users: [recipientId],
    );

    context.log('Notification sent to $recipientId');
    return context.res.json({
      'success': true,
      'message': 'Notification sent.'
    });

  } catch (e) {
    context.error('Failed to send notification: $e');
    // We don't want to fail the whole request if notification fails, usually.
    // But since this is a standalone action, we might return error.
    // However, when called internally, we might want to catch it there.
    return context.res.json({
      'success': false,
      'error': e.toString()
    }, 500);
  }
}
