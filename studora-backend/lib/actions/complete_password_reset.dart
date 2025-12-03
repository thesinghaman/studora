import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/appwrite_client.dart';
import '../utils/app_config.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';

Future<dynamic> completePasswordReset(context) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);

  // Admin Client (for password update)
  final adminClient = AppwriteClient.init();
  final users = Users(adminClient);

  // Public Client (for OTP verification)
  final publicClient = Client()
      .setEndpoint(AppConfig.endpoint)
      .setProject(AppConfig.projectId);
  final account = Account(publicClient);

  try {
    final body = jsonDecode(context.req.bodyRaw);
    final String? userId = body['userId'];
    final String? secret = body['secret'];
    final String? newPassword = body['newPassword'];

    if (userId == null || secret == null || newPassword == null) {
      return response.error(message: 'Missing required fields', statusCode: 400);
    }

    logger.info('Completing password reset', {'userId': userId});

    // 1. Verify OTP by creating a session
    try {
      final session = await account.createSession(
        userId: userId,
        secret: secret,
      );
      
      // 2. Force Update Password (Admin)
      await users.updatePassword(
        userId: userId,
        password: newPassword,
      );

      // 3. Cleanup: Delete the session we just created
      await users.deleteSession(
        userId: userId,
        sessionId: session.$id,
      );

      logger.info('Password reset successful', {'userId': userId});
      return response.success(null, message: 'Password updated successfully');

    } on AppwriteException catch (e) {
      if (e.code == 401) {
        logger.info('Invalid verification code provided', {'userId': userId});
        return response.error(message: 'Invalid verification code', statusCode: 401);
      }
      rethrow;
    }

  } catch (e, s) {
    logger.error("Error completing password reset", e, s);
    return response.error(message: 'Internal server error', statusCode: 500, details: e.toString());
  }
}
