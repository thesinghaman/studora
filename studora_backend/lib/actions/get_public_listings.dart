import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';

Future<dynamic> getPublicListings(dynamic context, Client client, Map<String, dynamic> body) async {
  final databases = Databases(client);

  final listingType = body['listingType'];
  final collegeId = body['collegeId'];
  final categoryIds = body['categoryIds'];
  final searchQuery = body['searchQuery'];
  final limit = body['limit'] ?? 15;
  final offset = body['offset'] ?? 0;
  final sortBy = body['sortBy'] ?? 'date_desc';
  final minPrice = body['minPrice'];
  final maxPrice = body['maxPrice'];
  final startDate = body['startDate'];
  final endDate = body['endDate'];
  
  // In Dart Runtime, headers are in context.req.headers
  // Note: Headers keys are usually lowercase in some environments, but let's check standard.
  final headers = context.req.headers as Map<String, dynamic>;
  final requestingUserId = headers['x-appwrite-user-id'];

  final baseQueries = [Query.equal('isActive', true)];

  if (minPrice is num) {
    baseQueries.add(Query.greaterThanEqual('price', minPrice));
  }
  if (maxPrice is num && maxPrice > 0) {
    baseQueries.add(Query.lessThanEqual('price', maxPrice));
  }

  String collectionId;
  String dateAttribute;

  if (listingType == 'marketplace' || listingType == 'rental') {
    collectionId = Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']!;
    dateAttribute = 'datePosted';
    baseQueries.add(Query.equal('adStatus', 'Active'));
    if (listingType == 'marketplace') {
      baseQueries.add(Query.equal('isRental', false));
    }
    if (listingType == 'rental') {
      baseQueries.add(Query.equal('isRental', true));
    }
  } else if (listingType == 'lost' || listingType == 'found') {
    collectionId = Platform.environment['APPWRITE_LOSTFOUND_COLLECTION_ID']!;
    dateAttribute = 'dateReported';
    baseQueries.add(Query.equal('type', listingType));
  } else {
    return context.res.json({'success': false, 'message': 'Invalid listingType: $listingType'}, 400);
  }

  if (collegeId != null) {
    final collegeField = collectionId == Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']
        ? 'collegeId'
        : 'reporterCollegeId';
    baseQueries.add(Query.equal(collegeField, collegeId));
  }

  if (categoryIds != null && categoryIds is List && categoryIds.isNotEmpty) {
    // Query.equal with array value works as "contains any" in Appwrite? 
    // No, Query.equal('attr', [v1, v2]) matches if attr is one of v1, v2.
    baseQueries.add(Query.equal('categoryId', categoryIds));
    context.log('Applying category filter: $categoryIds');
  }

  if (startDate != null) {
    baseQueries.add(Query.greaterThanEqual(dateAttribute, startDate));
  }
  if (endDate != null) {
    baseQueries.add(Query.lessThanEqual(dateAttribute, endDate));
  }

  List<Document> documents = [];

  if (searchQuery != null && (searchQuery as String).trim().isNotEmpty) {
    final searchLimit = 250;
    final q = searchQuery.trim();
    
    // Parallel search queries
    final futures = <Future<DocumentList>>[
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [...baseQueries, Query.search('title', q), Query.limit(searchLimit)],
      ),
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [...baseQueries, Query.search('searchTags', q), Query.limit(searchLimit)],
      ),
      databases.listDocuments(
        databaseId: Platform.environment['APPWRITE_DATABASE_ID']!,
        collectionId: collectionId,
        queries: [...baseQueries, Query.search('description', q), Query.limit(searchLimit)],
      ),
    ];

    final results = await Future.wait(futures);
    
    final rankedDocs = <String, Document>{};
    
    // Prioritize Title > Tags > Description
    for (final doc in results[0].documents) rankedDocs.putIfAbsent(doc.$id, () => doc);
    for (final doc in results[1].documents) rankedDocs.putIfAbsent(doc.$id, () => doc);
    for (final doc in results[2].documents) rankedDocs.putIfAbsent(doc.$id, () => doc);

    documents = rankedDocs.values.toList();

    // Sort in memory
    documents.sort((a, b) {
      switch (sortBy) {
        case 'price_asc':
          return ((a.data['price'] ?? 0) as num).compareTo((b.data['price'] ?? 0) as num);
        case 'price_desc':
          return ((b.data['price'] ?? 0) as num).compareTo((a.data['price'] ?? 0) as num);
        case 'date_asc':
          return DateTime.parse(a.$createdAt).compareTo(DateTime.parse(b.$createdAt));
        case 'date_desc':
        default:
          return DateTime.parse(b.$createdAt).compareTo(DateTime.parse(a.$createdAt));
      }
    });

    // Pagination in memory
    if (offset < documents.length) {
      documents = documents.sublist(offset, (offset + limit < documents.length) ? offset + limit : documents.length);
    } else {
      documents = [];
    }

  } else {
    // Standard DB Query
    switch (sortBy) {
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
      queries: [...baseQueries, Query.limit(limit), Query.offset(offset)],
    );
    documents = response.documents;
  }

  var filteredDocs = documents;
  final authorField = collectionId == Platform.environment['APPWRITE_ITEMS_COLLECTION_ID']
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

      final iHaveBlockedThem = List<String>.from(userDoc.data['blockedUsers'] ?? []);
      
      // Filter out docs from users I blocked
      filteredDocs = documents.where((doc) => !iHaveBlockedThem.contains(doc.data[authorField])).toList();

    } catch (e) {
      context.error('Error fetching requesting user profile: $e');
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
        queries: [Query.equal('\$id', authorIds), Query.limit(authorIds.length)],
      );

      for (final profile in authorProfiles.documents) {
        authorMap[profile.$id] = profile;
      }
    } catch (e) {
      context.error('Error fetching author profiles: $e');
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
      filteredDocs = filteredDocs.where((doc) => !theyHaveBlockedMe.contains(doc.data[authorField])).toList();
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
      docMap['sellerName'] = authorProfile.data['name'] ?? 'Unknown Seller';
      docMap['sellerProfilePicUrl'] = authorProfile.data['profilePicUrl'];
    } else {
      docMap['sellerName'] = 'Unknown Seller';
    }
    return docMap;
  }).toList();

  return context.res.json({
    'success': true,
    'data': results
  });
}
