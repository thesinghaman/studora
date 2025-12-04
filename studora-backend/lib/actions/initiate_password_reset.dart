import 'package:dart_appwrite/dart_appwrite.dart';

import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/auth_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> initiatePasswordReset(
  dynamic context,
  Client client,
  Map<String, dynamic> body,
) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final users = Users(client);

  // 1. Validate Input (Throws ValidationError if invalid)
  final request = InitiatePasswordResetRequest.fromMap(body);

  logger.info('Initiating password reset', {'email': request.email});

  // 2. Find user by email
  final userList = await users.list(
    queries: [Query.equal('email', request.email)],
  );

  if (userList.total == 0) {
    logger.info('User not found for password reset', {'email': request.email});
    throw NotFoundError('User not found');
  }

  final user = userList.users[0];

  return response.success({'userId': user.$id});
}
