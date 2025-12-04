import 'package:dart_appwrite/dart_appwrite.dart';

import '../utils/app_config.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/auth_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> completePasswordReset(
  dynamic context,
  Client client,
  Map<String, dynamic> body,
) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);

  // 1. Validate Input
  final request = CompletePasswordResetRequest.fromMap(body);

  // Admin Client (for password update) - reused from main
  final users = Users(client);

  // Public Client (for OTP verification)
  final publicClient =
      Client().setEndpoint(AppConfig.endpoint).setProject(AppConfig.projectId);
  final account = Account(publicClient);

  logger.info('Completing password reset', {'userId': request.userId});

  // 2. Verify OTP by creating a session
  try {
    final session = await account.createSession(
      userId: request.userId,
      secret: request.secret,
    );

    // 3. Force Update Password (Admin)
    await users.updatePassword(
      userId: request.userId,
      password: request.newPassword,
    );

    // 4. Cleanup: Delete the session we just created
    await users.deleteSession(
      userId: request.userId,
      sessionId: session.$id,
    );

    return response.success({'message': 'Password reset successful'});
  } on AppwriteException catch (e) {
    if (e.code == 401) {
      logger.info(
          'Invalid verification code provided', {'userId': request.userId});
      throw UnauthorizedError('Invalid verification code');
    }
    rethrow; // Let main.dart handle other Appwrite errors
  }
}
