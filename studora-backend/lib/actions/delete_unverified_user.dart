import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/user_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> deleteUnverifiedUser(dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final users = Users(client);
  final databases = Databases(client);

  // 1. Input Validation
  final request = DeleteUnverifiedUserRequest.fromMap(data);

  // 2. Verify JWT and User Identity
  final userClient = Client()
    .setEndpoint(Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1')
    .setProject(Platform.environment['APPWRITE_PROJECT_ID'] ?? '')
    .setJWT(request.jwt);
  
  final userAccount = Account(userClient);
  
  // We need to catch errors here specifically for JWT validation
  User user;
  try {
    user = await userAccount.get();
  } catch (e) {
    if (e is AppwriteException && e.code == 401) {
      throw UnauthorizedError('Invalid session token.');
    }
    rethrow;
  }

  if (user.$id != request.userIdToDelete) {
    logger.error('SECURITY ALERT: JWT mismatch for user ${request.userIdToDelete}');
    throw UnauthorizedError('JWT does not match user ID.');
  }

  if (user.emailVerification) {
    logger.info('Attempted to delete VERIFIED user ${request.userIdToDelete}. Blocked.');
    throw ValidationError('Cannot delete a verified user account.');
  }

  logger.info('JWT validated for unverified user ${user.$id}. Proceeding.');

  // 3. Delete Database Profile
  try {
    await databases.deleteDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: request.userIdToDelete,
    );
    logger.info('Deleted database profile for ${request.userIdToDelete}');
  } catch (e) {
    if (e is AppwriteException && e.code == 404) {
      logger.info('Database profile already deleted.');
    } else {
      rethrow;
    }
  }

  // 4. Delete Auth User
  await users.delete(userId: request.userIdToDelete);
  logger.info('Deleted auth record for ${request.userIdToDelete}');

  return response.success({'message': 'Account permanently deleted.'});
}
