import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/appwrite_client.dart';

Future<dynamic> completePasswordReset(context) async {
  // Admin Client (for password update)
  final adminClient = AppwriteClient.init();
  final users = Users(adminClient);

  // Public Client (for OTP verification)
  final publicClient = Client()
      .setEndpoint(Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1')
      .setProject(Platform.environment['APPWRITE_PROJECT_ID'] ?? '');
  final account = Account(publicClient);

  try {
    final body = jsonDecode(context.req.bodyRaw);
    final String userId = body['userId'];
    final String secret = body['secret'];
    final String newPassword = body['newPassword'];

    // 1. Verify OTP by creating a session
    // We need to impersonate the user to verify the OTP
    try {
      final session = await account.createSession(
        userId: userId,
        secret: secret,
      );
      
      // If successful, we have a session. We should delete it immediately
      // so the "backend" doesn't hold a session, although it's stateless.
      // Actually, we can't easily delete THIS session using the Admin API 
      // without knowing the sessionId, which createSession returns.
      
      // 2. Force Update Password (Admin)
      await users.updatePassword(
        userId: userId,
        password: newPassword,
      );

      // 3. Cleanup: Delete the session we just created to ensure no lingering access
      // We use the Client (which now has the session cookie? No, dart_appwrite Client doesn't auto-manage cookies like web)
      // Wait, `createSession` returns a Session object.
      // To delete it, we can use the Admin API: users.deleteSession(userId, sessionId)
      await users.deleteSession(
        userId: userId,
        sessionId: session.$id,
      );

      return context.res.json({
        'success': true,
        'message': 'Password updated successfully',
      });

    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return context.res.json({
          'success': false,
          'message': 'Invalid verification code',
        }, statusCode: 401);
      }
      rethrow;
    }

  } catch (e) {
    context.error("Error completing password reset: $e");
    return context.res.json({
      'success': false,
      'message': 'Internal server error: $e',
    }, statusCode: 500);
  }
}
