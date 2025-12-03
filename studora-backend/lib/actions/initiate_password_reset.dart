import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import '../utils/appwrite_client.dart';

Future<dynamic> initiatePasswordReset(context) async {
  final client = AppwriteClient.init();
  final users = Users(client);

  try {
    final body = jsonDecode(context.req.bodyRaw);
    final String email = body['email'];

    // 1. Find user by email
    final userList = await users.list(
      queries: [Query.equal('email', email)],
    );

    if (userList.total == 0) {
      return context.res.json({
        'success': false,
        'message': 'User not found',
      }, statusCode: 404);
    }

    final user = userList.users[0];

    return context.res.json({
      'success': true,
      'userId': user.$id,
    });
  } catch (e) {
    context.error("Error initiating password reset: $e");
    return context.res.json({
      'success': false,
      'message': 'Internal server error: $e',
    }, statusCode: 500);
  }
}
