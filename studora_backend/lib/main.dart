import 'dart:async';
import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'utils/appwrite_client.dart';

// Import actions
import 'actions/create_message.dart';
import 'actions/delete_conversations.dart';
import 'actions/delete_unverified_user.dart';
import 'actions/delete_user_account.dart';
import 'actions/get_public_listings.dart';
import 'actions/get_user_profile.dart';
import 'actions/mark_messages_as_read.dart';
import 'actions/notify_on_new_message.dart';
import 'actions/update_conversations.dart';

Future<dynamic> main(final context) async {
  final client = AppwriteClient.init();
  
  try {
    // Parse the request body
    final body = context.req.bodyRaw is String 
        ? jsonDecode(context.req.bodyRaw) 
        : context.req.body;

    final action = body['action'];

    context.log('Running action: $action');

    switch (action) {
      case 'create_message':
        return await createMessage(context, client, body);
      case 'notify_on_new_message':
        return await notifyOnNewMessage(context, client, body);
      case 'update_conversations':
        return await updateConversations(context, client, body);
      case 'delete_user_account':
        return await deleteUserAccount(context, client, body);
      case 'delete_conversations':
        return await deleteConversations(context, client, body);
      case 'delete_unverified_user':
        return await deleteUnverifiedUser(context, client, body);
      case 'get_public_listings':
        return await getPublicListings(context, client, body);
      case 'get_user_profile':
        return await getUserProfile(context, client, body);
      case 'mark_messages_as_read':
        return await markMessagesAsRead(context, client, body);
      
      default:
        return context.res.json({
          'success': false,
          'error': 'Invalid Action: $action'
        }, 400);
    }
  } catch (e, stack) {
    context.error('Error executing function: $e');
    context.error(stack.toString());
    return context.res.json({
      'success': false,
      'error': e.toString()
    }, 500);
  }
}
