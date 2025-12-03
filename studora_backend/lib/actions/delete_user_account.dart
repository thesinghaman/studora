import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:http/http.dart' as http;

Future<dynamic> deleteUserAccount(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);
  final storage = Storage(client);
  final users = Users(client);

  final userId = body['userId'];
  final password = body['password'];

  if (userId == null || password == null) {
    return context.res.json({'success': false, 'message': 'User ID and password are required.'});
  }

  try {
    // 1. Verify Password
    // Since dart_appwrite (Server SDK) doesn't have Account service to verify password,
    // we use a raw HTTP request to the Client API endpoint.
    final userDoc = await databases.getDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: userId,
    );
    final email = userDoc.data['email'];

    final endpoint = Platform.environment['APPWRITE_ENDPOINT'] ?? 'https://cloud.appwrite.io/v1';
    final projectId = Platform.environment['APPWRITE_PROJECT_ID']!;

    final verifyResponse = await http.post(
      Uri.parse('$endpoint/account/sessions/email'),
      headers: {
        'X-Appwrite-Project': projectId,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (verifyResponse.statusCode >= 400) {
      context.log('Password verification failed: ${verifyResponse.body}');
      return context.res.json({
        'success': false,
        'message': 'Incorrect password. Please try again.',
      });
    }
    
    context.log('Password verified for user $userId. Starting deletion process.');

    // 2. Delete Profile Picture (Avatar)
    final avatarFileId = userDoc.data['userAvatarFileId'];
    if (avatarFileId != null) {
      try {
        await storage.deleteFile(
          bucketId: Platform.environment['APPWRITE_AVATARS_BUCKET_ID']!,
          fileId: avatarFileId,
        );
        context.log('Deleted avatar $avatarFileId.');
      } catch (e) {
        // Ignore 404
        if (e is AppwriteException && e.code == 404) {
          // ok
        } else {
          context.error('Could not delete avatar: $e');
        }
      }
    }

    // 3. Delete User's Ads (Items)
    await _deleteUserDocuments(
      context, 
      databases, 
      storage, 
      Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']!, 
      'sellerId', 
      userId,
      Platform.environment['APPWRITE_ITEMS_BUCKET_ID']!
    );

    // 4. Delete User's Lost & Found Posts
    await _deleteUserDocuments(
      context, 
      databases, 
      storage, 
      Platform.environment['APPWRITE_LOSTFOUND_COLLECTION_ID']!, 
      'reporterId', 
      userId,
      Platform.environment['APPWRITE_ITEMS_BUCKET_ID']!
    );

    // 5. Mark User's Conversations as Deleted
    await _markConversationsDeleted(context, databases, userId);

    // 6. Delete User's Profile Document
    await databases.deleteDocument(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
      documentId: userId,
    );
    context.log('Deleted user profile document $userId.');

    // 7. Delete Auth User
    await users.delete(userId: userId);
    context.log('Successfully deleted auth user $userId.');

    return context.res.json({
      'success': true,
      'message': 'User account deleted successfully.',
    });

  } catch (e) {
    context.error('Error during user deletion: $e');
    return context.res.json({
      'success': false,
      'message': 'A server error occurred during account deletion.',
    });
  }
}

Future<void> _deleteUserDocuments(
  dynamic context,
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
      await _deleteImagesForDocument(context, doc, storage, bucketId);
      await databases.deleteDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        documentId: doc.$id,
      );
    }
    
    if (response.documents.isNotEmpty) {
      context.log('Processed batch of ${response.documents.length} items from $collectionId');
    }
  }
}

Future<void> _deleteImagesForDocument(
  dynamic context,
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
          context.error('Failed to parse URL $url: $e');
        }
      }
    }
  }

  if (fileIdsToDelete.isEmpty) return;

  context.log('Deleting ${fileIdsToDelete.length} images for ${doc.$id}');
  
  await Future.wait(fileIdsToDelete.map((fileId) async {
    try {
      await storage.deleteFile(bucketId: bucketId, fileId: fileId);
    } catch (e) {
      if (e is AppwriteException && e.code == 404) return;
      context.error('Failed to delete file $fileId: $e');
    }
  }));
}

Future<void> _markConversationsDeleted(dynamic context, Databases databases, String userId) async {
  // Note: Limit 5000 might be too high for one go, but following original logic
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
      collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
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
        collectionId: Platform.environment['APPWRITE_CONVERSATIONS_COLLECTION_ID']!,
        documentId: convo.$id,
        data: {'deletedBy': deletedBy},
      );
    }
  }
  context.log('Marked ${allDocs.length} conversations as deleted.');
}
