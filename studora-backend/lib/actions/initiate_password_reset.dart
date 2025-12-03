import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/appwrite_client.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';

Future<dynamic> initiatePasswordReset(context) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final client = AppwriteClient.init();
  final users = Users(client);

  try {
    final body = jsonDecode(context.req.bodyRaw);
    final String? email = body['email'];

    if (email == null || email.isEmpty) {
      return response.error(message: 'Email is required', statusCode: 400);
    }

    logger.info('Initiating password reset', {'email': email});

    // 1. Find user by email
    final userList = await users.list(
      queries: [Query.equal('email', email)],
    );

    if (userList.total == 0) {
      logger.info('User not found for password reset', {'email': email});
      return response.error(message: 'User not found', statusCode: 404);
    }

    final user = userList.users[0];

    return response.success({'userId': user.$id});
  } catch (e, s) {
    logger.error("Error initiating password reset", e, s);
    return response.error(message: 'Internal server error', statusCode: 500, details: e.toString());
  }
}
