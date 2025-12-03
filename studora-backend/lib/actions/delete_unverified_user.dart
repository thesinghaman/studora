import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> deleteUnverifiedUser(dynamic context, Client client, Map<String, dynamic> body) async {
  // Note: This function requires Admin privileges (API Key with Users.write scope)
  // The `client` passed here is initialized with the API Key from environment, so it has admin access.
  
  final users = Users(client);
  final databases = Databases(client);

  final userIdToDelete = body['userIdToDelete'];
  final jwt = body['jwt'];

  if (userIdToDelete == null || userIdToDelete is! String) {
    return context.res.json({'success': false, 'message': 'Bad Request: `userIdToDelete` is required.'}, 400);
  }
  if (jwt == null || jwt is! String) {
    return context.res.json({'success': false, 'message': 'Bad Request: `jwt` is required.'}, 400);
  }

  try {
    // Verify JWT and User Identity
    final userClient = Client()
      .setEndpoint(Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1')
      .setProject(Platform.environment['APPWRITE_PROJECT_ID'] ?? '')
      .setJWT(jwt);
    
    final userAccount = Account(userClient);
    final user = await userAccount.get();

    if (user.$id != userIdToDelete) {
      context.error('SECURITY ALERT: JWT mismatch for user $userIdToDelete');
      return context.res.json({'success': false, 'message': 'Forbidden: JWT does not match user ID.'}, 403);
    }

    if (user.emailVerification) {
      context.log('Attempted to delete VERIFIED user $userIdToDelete. Blocked.');
      return context.res.json({'success': false, 'message': 'Bad Request: Cannot delete a verified user account.'}, 400);
    }

    context.log('JWT validated for unverified user ${user.$id}. Proceeding.');

    // Delete Database Profile
    try {
      await databases.deleteDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
        documentId: userIdToDelete,
      );
      context.log('Deleted database profile for $userIdToDelete');
    } catch (e) {
      if (e is AppwriteException && e.code == 404) {
        context.log('Database profile already deleted.');
      } else {
        rethrow;
      }
    }

    // Delete Auth User
    await users.delete(userId: userIdToDelete);
    context.log('Deleted auth record for $userIdToDelete');

    return context.res.json({'success': true, 'message': 'Account permanently deleted.'});

  } catch (e) {
    context.error('Error deleting unverified user: $e');
    if (e is AppwriteException && e.code == 401) {
       return context.res.json({'success': false, 'message': 'Forbidden: Invalid session token.'}, 401);
    }
    return context.res.json({'success': false, 'message': 'An internal server error occurred.'}, 500);
  }
}
