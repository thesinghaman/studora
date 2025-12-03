import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> getUserProfile(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);

  if (context.req.method != 'POST') {
    return context.res.json({'success': false, 'message': 'Method not allowed'}, 405);
  }

  final targetUserId = body['targetUserId'];
  if (targetUserId == null) {
    return context.res.json({'success': false, 'message': 'Missing required field: targetUserId.'}, 400);
  }

  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];

  if (requestingUserId == null) {
    return context.res.json({'success': false, 'message': 'Authentication required.'}, 401);
  }

  try {
    final targetUserDoc = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: targetUserId,
    );

    final blockedUsers = List<String>.from(targetUserDoc.data['blockedUsers'] ?? []);
    final isRequesterBlocked = blockedUsers.contains(requestingUserId);

    Map<String, dynamic> userProfile;

    if (isRequesterBlocked) {
      context.log('Request from blocked user $requestingUserId to $targetUserId.');
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
      context.log('Request from user $requestingUserId to $targetUserId.');
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
        'isOnline': showLastSeen ? (targetUserDoc.data['isOnline'] ?? false) : false,
        'lastSeen': showLastSeen ? targetUserDoc.data['lastSeen'] : null,
        'showReadReceipts': targetUserDoc.data['showReadReceipts'],
      };
    }

    return context.res.json({'success': true, 'data': userProfile});

  } catch (e) {
    context.error('Error fetching user profile for $targetUserId: $e');
    if (e is AppwriteException && e.code == 404) {
      return context.res.json({'success': false, 'message': 'User not found.'}, 404);
    }
    return context.res.json({'success': false, 'message': 'An error occurred on the server.'}, 500);
  }
}
