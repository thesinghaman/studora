import 'dart:async';
import 'dart:convert';

import 'package:dart_appwrite/dart_appwrite.dart';

import 'utils/appwrite_client.dart';
import 'utils/app_config.dart';
import 'utils/logger.dart';
import 'utils/response_helper.dart';
import 'utils/exceptions.dart';

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
import 'actions/initiate_password_reset.dart';
import 'actions/complete_password_reset.dart';

Future<dynamic> main(final context) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);

  try {
    // 1. Validate Configuration
    AppConfig.validate();

    // 2. Initialize Client
    final client = AppwriteClient.init();

    // 3. Parse Request
    final body = context.req.bodyRaw is String
        ? jsonDecode(context.req.bodyRaw)
        : context.req.body;

    final action = body['action'];
    logger.info('Dispatcher received action', {'action': action});

    // 4. Dispatch Action
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
      case 'initiate_password_reset':
        return await initiatePasswordReset(context, client, body);
      case 'complete_password_reset':
        return await completePasswordReset(context, client, body);

      default:
        logger.error('Invalid Action requested: $action');
        return response.error(
          message: 'Invalid Action: $action',
          code: 'INVALID_ACTION',
          statusCode: 400,
        );
    }
  } on AppError catch (e) {
    logger.error('AppError: ${e.message}', e);
    return response.error(
      message: e.message,
      statusCode: e.statusCode,
      code: e.code,
    );
  } on AppwriteException catch (e) {
    logger.error('AppwriteException: ${e.message}', e);
    return response.error(
      message: e.message ?? 'Appwrite Error',
      statusCode: e.code ?? 500,
      code: 'APPWRITE_ERROR',
    );
  } catch (e, stack) {
    logger.error('Unhandled Exception in Main Dispatcher', e, stack);
    return response.error(
      message: 'Internal Server Error',
      code: 'INTERNAL_SERVER_ERROR',
      statusCode: 500,
      details: e.toString(),
    );
  }
}
