import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/chat_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> notifyOnNewMessage(dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final messaging = Messaging(client);
  final databases = Databases(client);

  // 1. Input Validation
  final request = NotifyOnNewMessageRequest.fromMap(data);

  final recipientId = request.participants.firstWhere((p) => p != request.senderId, orElse: () => '');

  if (recipientId.isEmpty) {
    return response.success({'message': 'No recipient to notify.'});
  }

  try {
    // Fetch sender's name
    final senderUserDoc = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: request.senderId,
    );

    final senderName = senderUserDoc.data['name'] ?? 'Someone';

    // Send Push Notification
    final body = request.messageType == 'image' ? '📷 Sent you an image' : request.text ?? 'Sent you a message';
    
    await messaging.createPush(
      messageId: ID.unique(),
      title: 'New Message from $senderName',
      body: body,
      data: {
        'conversationId': request.conversationId ?? '',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      users: [recipientId],
    );

    logger.info('Notification sent to $recipientId');
    return response.success({'message': 'Notification sent.'});

  } catch (e) {
    logger.error('Failed to send notification', e);
    // Return success to avoid breaking the flow if called internally
    return response.success({'message': 'Notification failed but logged.'});
  }
}
