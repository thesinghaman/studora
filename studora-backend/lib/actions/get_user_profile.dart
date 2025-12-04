import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';

import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/user_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> getUserProfile(
    dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);

  // 1. Input Validation
  final request = GetUserProfileRequest.fromMap(data);

  // 2. Get Requesting User ID from Headers (passed by Appwrite Function)
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];

  if (requestingUserId == null) {
    throw UnauthorizedError('Authentication required.');
  }

  try {
    final targetUserDoc = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: request.targetUserId,
    );

    final blockedUsers =
        List<String>.from(targetUserDoc.data['blockedUsers'] ?? []);
    final isRequesterBlocked = blockedUsers.contains(requestingUserId);

    Map<String, dynamic> userProfile;

    if (isRequesterBlocked) {
      logger.info(
          'Request from blocked user $requestingUserId to ${request.targetUserId}.');
      userProfile = {
        'userId': targetUserDoc.$id,
        'userName': targetUserDoc.data['userName'],
        'userAvatarUrl': null,
        'email': 'private',
        'rollNumber': 'private',
        'hostel': null,
        'isOnline': false,
        'lastSeen': null,
        'dateJoined': null,
        'isBlocked': true,
      };
    } else {
      logger.info(
          'Request from user $requestingUserId to ${request.targetUserId}.');
      final showLastSeen = targetUserDoc.data['showLastSeen'] ?? false;
      userProfile = {
        'userId': targetUserDoc.$id,
        'userName': targetUserDoc.data['userName'],
        'userAvatarUrl': targetUserDoc.data['userAvatarUrl'],
        'email': targetUserDoc.data['email'],
        'rollNumber': targetUserDoc.data['rollNumber'],
        'hostel': targetUserDoc.data['hostel'],
        'dateJoined': targetUserDoc.data['dateJoined'],
        'isBlocked': false,
        'isOnline':
            showLastSeen ? (targetUserDoc.data['isOnline'] ?? false) : false,
        'lastSeen': showLastSeen ? targetUserDoc.data['lastSeen'] : null,
        'showReadReceipts': targetUserDoc.data['showReadReceipts'],
      };
    }

    return response.success(userProfile);
  } catch (e) {
    if (e is AppwriteException && e.code == 404) {
      throw NotFoundError('User not found.');
    }
    rethrow;
  }
}
