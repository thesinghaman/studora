import 'dart:convert';
import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:http/http.dart' as http;

import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/user_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> deleteUserAccount(
    dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);
  final storage = Storage(client);
  final users = Users(client);

  // 1. Input Validation
  final request = DeleteUserAccountRequest.fromMap(data);

  // 2. Verify Password
  // Since dart_appwrite (Server SDK) doesn't have Account service to verify password,
  // we use a raw HTTP request to the Client API endpoint.
  final userDoc = await databases.getDocument(
    databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
    collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
    documentId: request.userId,
  );
  final email = userDoc.data['email'];

  final endpoint = Platform.environment['APPWRITE_ENDPOINT'] ??
      'https://cloud.appwrite.io/v1';
  final projectId = Platform.environment['APPWRITE_PROJECT_ID']!;

  final verifyResponse = await http.post(
    Uri.parse('$endpoint/account/sessions/email'),
    headers: {
      'X-Appwrite-Project': projectId,
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': request.password,
    }),
  );

  if (verifyResponse.statusCode >= 400) {
    logger.info('Password verification failed: ${verifyResponse.body}');
    throw ValidationError('Incorrect password. Please try again.');
  }

  logger.info(
      'Password verified for user ${request.userId}. Starting deletion process.');

  // 3. Delete Profile Picture (Avatar)
  final avatarFileId = userDoc.data['userAvatarFileId'];
  if (avatarFileId != null) {
    try {
      await storage.deleteFile(
        bucketId: Platform.environment['APPWRITE_AVATARS_BUCKET_ID']!,
        fileId: avatarFileId,
      );
      logger.info('Deleted avatar $avatarFileId.');
    } catch (e) {
      // Ignore 404
      if (e is AppwriteException && e.code == 404) {
        // ok
      } else {
        logger.error('Could not delete avatar', e);
      }
    }
  }

  // 4. Delete User's Ads (Items)
  await _deleteUserDocuments(
      logger,
      databases,
      storage,
      Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']!,
      'sellerId',
      request.userId,
      Platform.environment['APPWRITE_ITEMS_BUCKET_ID']!);

  // 5. Delete User's Lost & Found Posts
  await _deleteUserDocuments(
      logger,
      databases,
      storage,
      Platform.environment['APPWRITE_LOSTFOUND_COLLECTION_ID']!,
      'reporterId',
      request.userId,
      Platform.environment['APPWRITE_ITEMS_BUCKET_ID']!);

  // 6. Mark User's Conversations as Deleted
  await _markConversationsDeleted(logger, databases, request.userId);

  // 7. Delete User's Profile Document
  await databases.deleteDocument(
    databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
    collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
    documentId: request.userId,
  );
  logger.info('Deleted user profile document ${request.userId}.');

  // 8. Delete Auth User
  await users.delete(userId: request.userId);
  logger.info('Successfully deleted auth user ${request.userId}.');

  return response.success({'message': 'User account deleted successfully.'});
}

Future<void> _deleteUserDocuments(
  Logger logger,
  Databases databases,
  Storage storage,
  String collectionId,
  String userIdField,
  String userId,
  String bucketId,
) async {
  bool hasMore = true;
  while (hasMore) {
    final response = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: collectionId,
      queries: [
        Query.equal(userIdField, userId),
        Query.limit(100),
      ],
    );

    hasMore = response.documents.length == 100;

    for (final doc in response.documents) {
      await _deleteImagesForDocument(logger, doc, storage, bucketId);
      await databases.deleteDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        documentId: doc.$id,
      );
    }

    if (response.documents.isNotEmpty) {
      logger.info(
          'Processed batch of ${response.documents.length} items from $collectionId');
    }
  }
}

Future<void> _deleteImagesForDocument(
  Logger logger,
  Document doc,
  Storage storage,
  String bucketId,
) async {
  final fileIdsToDelete = <String>{};

  // 1. Direct file IDs
  final imageFileIds = doc.data['imageFileIds'];
  if (imageFileIds != null && imageFileIds is List) {
    fileIdsToDelete.addAll(imageFileIds.cast<String>());
  }
  // 2. Parse URLs
  else {
    final imageUrls = doc.data['imageUrls'];
    if (imageUrls != null && imageUrls is List) {
      for (final url in imageUrls) {
        try {
          // url format: .../files/FILE_ID/...
          final uri = Uri.parse(url.toString());
          final segments = uri.pathSegments;
          final filesIndex = segments.indexOf('files');
          if (filesIndex != -1 && filesIndex + 1 < segments.length) {
            fileIdsToDelete.add(segments[filesIndex + 1]);
          }
        } catch (e) {
          logger.error('Failed to parse URL $url', e);
        }
      }
    }
  }

  if (fileIdsToDelete.isEmpty) return;

  logger.info('Deleting ${fileIdsToDelete.length} images for ${doc.$id}');

  await Future.wait(fileIdsToDelete.map((fileId) async {
    try {
      await storage.deleteFile(bucketId: bucketId, fileId: fileId);
    } catch (e) {
      if (e is AppwriteException && e.code == 404) return;
      logger.error('Failed to delete file $fileId', e);
    }
  }));
}

Future<void> _markConversationsDeleted(
    Logger logger, Databases databases, String userId) async {
  // We use a loop to ensure we get all conversations.

  List<Document> allDocs = [];
  String? cursor;
  do {
    final queries = [
      Query.contains('participants', userId),
      Query.limit(100),
    ];
    if (cursor != null) queries.add(Query.cursorAfter(cursor));

    final res = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId:
          Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
      queries: queries,
    );
    allDocs.addAll(res.documents);
    if (res.documents.isNotEmpty) {
      cursor = res.documents.last.$id;
    } else {
      cursor = null;
    }
  } while (cursor != null);

  for (final convo in allDocs) {
    List<String> deletedBy = List<String>.from(convo.data['deletedBy'] ?? []);

    bool alreadyDeleted = false;
    for (var record in deletedBy) {
      try {
        final map = jsonDecode(record);
        if (map['userId'] == userId) {
          alreadyDeleted = true;
          break;
        }
      } catch (_) {}
    }

    if (!alreadyDeleted) {
      deletedBy.add(jsonEncode({
        'userId': userId,
        'deletedAt': DateTime.now().toIso8601String(),
      }));

      await databases.updateDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId:
            Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: convo.$id,
        data: {'deletedBy': deletedBy},
      );
    }
  }
  logger.info('Marked ${allDocs.length} conversations as deleted.');
}
