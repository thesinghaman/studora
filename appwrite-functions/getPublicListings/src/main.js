const { Client, Databases, Query } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const databases = new Databases(client);

  let body;
  try {
    body = JSON.parse(req.body);
  } catch (e) {
    return res.json({ success: false, message: 'Invalid JSON body.' }, 400);
  }

  const {
    listingType,
    collegeId,
    categoryIds,
    searchQuery,
    limit = 15,
    offset = 0,
    sortBy = 'date_desc',
    minPrice,
    maxPrice,
    startDate,
    endDate,
  } = body;
  const requestingUserId = req.headers['x-appwrite-user-id'];

  const baseQueries = [Query.equal('isActive', true)];

  if (typeof minPrice === 'number') {
    baseQueries.push(Query.greaterThanEqual('price', minPrice));
  }
  if (typeof maxPrice === 'number' && maxPrice > 0) {
    baseQueries.push(Query.lessThanEqual('price', maxPrice));
  }

  let collectionId;
  if (listingType === 'marketplace' || listingType === 'rental') {
    collectionId = process.env.APPWRITE_ITEMS_COLLECTION_ID;
    dateAttribute = 'datePosted';
    baseQueries.push(Query.equal('adStatus', 'Active'));
    if (listingType === 'marketplace')
      baseQueries.push(Query.equal('isRental', false));
    if (listingType === 'rental')
      baseQueries.push(Query.equal('isRental', true));
  } else if (listingType === 'lost' || listingType === 'found') {
    collectionId = process.env.APPWRITE_LOSTFOUND_COLLECTION_ID;
    dateAttribute = 'dateReported';
    baseQueries.push(Query.equal('type', listingType));
  } else {
    return res.json(
      {
        success: false,
        message: `Invalid listingType specified: ${listingType}`,
      },
      400
    );
  }

  if (collegeId) {
    const collegeField =
      collectionId === process.env.APPWRITE_ITEMS_COLLECTION_ID
        ? 'collegeId'
        : 'reporterCollegeId';
    baseQueries.push(Query.equal(collegeField, collegeId));
  }

  if (categoryIds && Array.isArray(categoryIds) && categoryIds.length > 0) {
    baseQueries.push(Query.equal('categoryId', categoryIds));
    log(`Applying category filter for IDs: ${categoryIds.join(', ')}`);
  }

  if (startDate) {
    baseQueries.push(Query.greaterThanEqual(dateAttribute, startDate));
  }
  if (endDate) {
    baseQueries.push(Query.lessThanEqual(dateAttribute, endDate));
  }

  let documents = [];

  if (searchQuery && searchQuery.trim() !== '') {
    const searchLimit = 250;
    const titleQuery = databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      collectionId,
      [
        ...baseQueries,
        Query.search('title', searchQuery),
        Query.limit(searchLimit),
      ]
    );
    const tagsQuery = databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      collectionId,
      [
        ...baseQueries,
        Query.search('searchTags', searchQuery),
        Query.limit(searchLimit),
      ]
    );
    const descriptionQuery = databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      collectionId,
      [
        ...baseQueries,
        Query.search('description', searchQuery),
        Query.limit(searchLimit),
      ]
    );
    const [titleResults, tagsResults, descriptionResults] =
      await Promise.allSettled([titleQuery, tagsQuery, descriptionQuery]);
    const rankedDocs = new Map();
    if (titleResults.status === 'fulfilled')
      titleResults.value.documents.forEach((doc) =>
        rankedDocs.set(doc.$id, doc)
      );
    if (tagsResults.status === 'fulfilled')
      tagsResults.value.documents.forEach((doc) => {
        if (!rankedDocs.has(doc.$id)) rankedDocs.set(doc.$id, doc);
      });
    if (descriptionResults.status === 'fulfilled')
      descriptionResults.value.documents.forEach((doc) => {
        if (!rankedDocs.has(doc.$id)) rankedDocs.set(doc.$id, doc);
      });
    documents = Array.from(rankedDocs.values());
    documents.sort((a, b) => {
      switch (sortBy) {
        case 'price_asc':
          return (a.price || 0) - (b.price || 0);
        case 'price_desc':
          return (b.price || 0) - (a.price || 0);
        case 'date_asc':
          return new Date(a.$createdAt) - new Date(b.$createdAt);
        case 'date_desc':
        default:
          return new Date(b.$createdAt) - new Date(a.$createdAt);
      }
    });
    documents = documents.slice(offset, offset + limit);
  } else {
    switch (sortBy) {
      case 'price_asc':
        baseQueries.push(Query.orderAsc('price'));
        break;
      case 'price_desc':
        baseQueries.push(Query.orderDesc('price'));
        break;
      case 'date_asc':
        baseQueries.push(Query.orderAsc('$createdAt'));
        break;
      case 'date_desc':
      default:
        baseQueries.push(Query.orderDesc('$createdAt'));
        break;
    }
    const response = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      collectionId,
      [...baseQueries, Query.limit(limit), Query.offset(offset)]
    );
    documents = response.documents;
  }

  if (!requestingUserId) {
    return res.json(documents);
  }

  try {
    const authorField =
      collectionId === process.env.APPWRITE_ITEMS_COLLECTION_ID
        ? 'sellerId'
        : 'reporterId';
    const userDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      requestingUserId
    );
    const iHaveBlockedThem = new Set(userDoc.blockedUsers || []);
    let filteredDocs = documents.filter(
      (doc) => !iHaveBlockedThem.has(doc[authorField])
    );
    const authorIds = [...new Set(filteredDocs.map((doc) => doc[authorField]))];

    if (authorIds.length > 0) {
      const authorProfiles = await databases.listDocuments(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_USERS_COLLECTION_ID,
        [Query.equal('$id', authorIds), Query.limit(authorIds.length)]
      );
      const theyHaveBlockedMe = new Set();
      for (const profile of authorProfiles.documents) {
        if (
          profile.blockedUsers &&
          profile.blockedUsers.includes(requestingUserId)
        ) {
          theyHaveBlockedMe.add(profile.$id);
        }
      }
      if (theyHaveBlockedMe.size > 0) {
        filteredDocs = filteredDocs.filter(
          (doc) => !theyHaveBlockedMe.has(doc[authorField])
        );
      }
    }
    return res.json(filteredDocs);
  } catch (e) {
    error(`Failed during filtering for user ${requestingUserId}: ${e.message}`);
    return res.json([], 500);
  }
};
