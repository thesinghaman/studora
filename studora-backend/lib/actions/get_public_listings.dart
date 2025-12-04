import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

import '../utils/logger.dart';
import '../utils/response_helper.dart';
import '../dtos/listing_dtos.dart';
import '../utils/exceptions.dart';

Future<dynamic> getPublicListings(
    dynamic context, Client client, Map<String, dynamic> data) async {
  final logger = Logger(context);
  final response = ResponseHelper(context);
  final databases = Databases(client);

  // 1. Input Validation
  final request = GetPublicListingsRequest.fromMap(data);

  // In Dart Runtime, headers are in context.req.headers
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];

  final baseQueries = [Query.equal('isActive', true)];

  if (request.minPrice != null) {
    baseQueries.add(Query.greaterThanEqual('price', request.minPrice));
  }
  if (request.maxPrice != null && request.maxPrice! > 0) {
    baseQueries.add(Query.lessThanEqual('price', request.maxPrice));
  }

  String collectionId;
  String dateAttribute;

  if (request.listingType == 'marketplace' || request.listingType == 'rental') {
    collectionId = Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']!;
    dateAttribute = 'datePosted';
    baseQueries.add(Query.equal('adStatus', 'Active'));
    if (request.listingType == 'marketplace') {
      baseQueries.add(Query.equal('isRental', false));
    }
    if (request.listingType == 'rental') {
      baseQueries.add(Query.equal('isRental', true));
    }
  } else if (request.listingType == 'lost' || request.listingType == 'found') {
    collectionId = Platform.environment['APPWRITE_LOSTFOUND_COLLECTION_ID']!;
    dateAttribute = 'dateReported';
    baseQueries.add(Query.equal('type', request.listingType));
  } else {
    throw ValidationError('Invalid listingType: ${request.listingType}');
  }

  if (request.collegeId != null) {
    final collegeField =
        collectionId == Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']
            ? 'collegeId'
            : 'reporterCollegeId';
    baseQueries.add(Query.equal(collegeField, request.collegeId));
  }

  if (request.categoryIds != null && request.categoryIds!.isNotEmpty) {
    baseQueries.add(Query.equal('categoryId', request.categoryIds));
    logger.info('Applying category filter: ${request.categoryIds}');
  }

  if (request.startDate != null) {
    baseQueries.add(Query.greaterThanEqual(dateAttribute, request.startDate));
  }
  if (request.endDate != null) {
    baseQueries.add(Query.lessThanEqual(dateAttribute, request.endDate));
  }

  List<Document> documents = [];

  if (request.searchQuery != null && request.searchQuery!.trim().isNotEmpty) {
    final searchLimit = 250;
    final q = request.searchQuery!.trim();

    // Parallel search queries
    final futures = <Future<DocumentList>>[
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [
          ...baseQueries,
          Query.search('title', q),
          Query.limit(searchLimit)
        ],
      ),
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [
          ...baseQueries,
          Query.search('searchTags', q),
          Query.limit(searchLimit)
        ],
      ),
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [
          ...baseQueries,
          Query.search('description', q),
          Query.limit(searchLimit)
        ],
      ),
    ];

    final results = await Future.wait(futures);

    final rankedDocs = <String, Document>{};

    // Prioritize Title > Tags > Description
    for (final doc in results[0].documents)
      rankedDocs.putIfAbsent(doc.$id, () => doc);
    for (final doc in results[1].documents)
      rankedDocs.putIfAbsent(doc.$id, () => doc);
    for (final doc in results[2].documents)
      rankedDocs.putIfAbsent(doc.$id, () => doc);

    documents = rankedDocs.values.toList();

    // Sort in memory
    documents.sort((a, b) {
      switch (request.sortBy) {
        case 'price_asc':
          return ((a.data['price'] ?? 0) as num)
              .compareTo((b.data['price'] ?? 0) as num);
        case 'price_desc':
          return ((b.data['price'] ?? 0) as num)
              .compareTo((a.data['price'] ?? 0) as num);
        case 'date_asc':
          return DateTime.parse(a.$createdAt)
              .compareTo(DateTime.parse(b.$createdAt));
        case 'date_desc':
        default:
          return DateTime.parse(b.$createdAt)
              .compareTo(DateTime.parse(a.$createdAt));
      }
    });

    // Pagination in memory
    if (request.offset < documents.length) {
      documents = documents.sublist(
          request.offset,
          (request.offset + request.limit < documents.length)
              ? request.offset + request.limit
              : documents.length);
    } else {
      documents = [];
    }
  } else {
    // Standard DB Query
    switch (request.sortBy) {
      case 'price_asc':
        baseQueries.add(Query.orderAsc('price'));
        break;
      case 'price_desc':
        baseQueries.add(Query.orderDesc('price'));
        break;
      case 'date_asc':
        baseQueries.add(Query.orderAsc('\$createdAt'));
        break;
      case 'date_desc':
      default:
        baseQueries.add(Query.orderDesc('\$createdAt'));
        break;
    }

    final response = await databases.listDocuments(
      databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
      collectionId: collectionId,
      queries: [
        ...baseQueries,
        Query.limit(request.limit),
        Query.offset(request.offset)
      ],
    );
    documents = response.documents;
  }

  var filteredDocs = documents;
  final authorField =
      collectionId == Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']
          ? 'sellerId'
          : 'reporterId';

  // 1. Filtering (Blocked Users) - Only if user is logged in
  if (requestingUserId != null) {
    try {
      // Fetch requesting user to see who THEY blocked
      final userDoc = await databases.getDocument(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
        documentId: requestingUserId,
      );

      final iHaveBlockedThem =
          List<String>.from(userDoc.data['blockedUsers'] ?? []);

      // Filter out docs from users I blocked
      filteredDocs = documents
          .where((doc) => !iHaveBlockedThem.contains(doc.data[authorField]))
          .toList();
    } catch (e) {
      logger.error('Error fetching requesting user profile', e);
      // Continue with unfiltered docs or fail? Let's continue but log error.
    }
  }

  // 2. Fetch Author Profiles (for Hydration AND "Blocked Me" check)
  final authorIds = filteredDocs
      .map((doc) => doc.data[authorField] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet()
      .toList();

  Map<String, Document> authorMap = {};

  if (authorIds.isNotEmpty) {
    try {
      // Chunk the IDs if necessary (Appwrite limit is usually around 100, but query length matters)
      // For safety, we can fetch in batches or just assume limit=15 is small enough.
      final authorProfiles = await databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: Platform.environment['APPWRITE_USERS_COLLECTION_ID']!,
        queries: [
          Query.equal('\$id', authorIds),
          Query.limit(authorIds.length)
        ],
      );

      for (final profile in authorProfiles.documents) {
        authorMap[profile.$id] = profile;
      }
    } catch (e) {
      logger.error('Error fetching author profiles', e);
    }
  }

  // 3. "Blocked Me" Check - Only if user is logged in
  if (requestingUserId != null) {
    final theyHaveBlockedMe = <String>{};
    for (final profile in authorMap.values) {
      final blocked = List<String>.from(profile.data['blockedUsers'] ?? []);
      if (blocked.contains(requestingUserId)) {
        theyHaveBlockedMe.add(profile.$id);
      }
    }

    if (theyHaveBlockedMe.isNotEmpty) {
      filteredDocs = filteredDocs
          .where((doc) => !theyHaveBlockedMe.contains(doc.data[authorField]))
          .toList();
    }
  }

  // 4. Hydration & Response Construction
  final results = filteredDocs.map((doc) {
    // Explicitly flatten the document to ensure attributes are at the top level
    final Map<String, dynamic> docMap = Map<String, dynamic>.from(doc.data);
    docMap['\$id'] = doc.$id;
    docMap['\$collectionId'] = doc.$collectionId;
    docMap['\$databaseId'] = doc.$databaseId;
    docMap['\$createdAt'] = doc.$createdAt;
    docMap['\$updatedAt'] = doc.$updatedAt;
    docMap['\$permissions'] = doc.$permissions;

    final authorId = doc.data[authorField] as String?;

    if (authorId != null && authorMap.containsKey(authorId)) {
      final authorProfile = authorMap[authorId]!;
      // Inject fields expected by frontend ItemModel
      // Check for 'userName' first (as seen in getUserProfile), then 'name'
      docMap['sellerName'] = authorProfile.data['userName'] ??
          authorProfile.data['name'] ??
          'Unknown Seller';
      docMap['sellerProfilePicUrl'] = authorProfile.data['userAvatarUrl'] ??
          authorProfile.data['profilePicUrl'];
    } else {
      docMap['sellerName'] = 'Unknown Seller';
    }
    return docMap;
  }).toList();

  return response.success(results);
}
