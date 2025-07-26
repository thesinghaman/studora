const { Client, Databases, Query } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  // 1. --- Client Init and Input Validation ---
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const databases = new Databases(client);

  let body;
  try {
    body = JSON.parse(req.body);
  } catch (e) {
    return res.json({ success: false, error: 'Invalid JSON body.' }, 400);
  }

  const { type } = body;

  // 2. --- Route to the correct logic based on type ---
  try {
    switch (type) {
      case 'itemUpdate':
        await handleItemUpdate(databases, body, log);
        return res.json({ success: true, message: 'Item update processed.' });

      case 'avatarUpdate':
        await handleAvatarUpdate(databases, body, log);
        return res.json({ success: true, message: 'Avatar update processed.' });

      default:
        error(`Invalid update type received: ${type}`);
        return res.json({ success: false, error: 'Invalid update type.' }, 400);
    }
  } catch (e) {
    error(`Failed to process update of type '${type}': ${e.message}`);
    return res.json({ success: false, error: e.message }, 500);
  }
};

// --- Logic for Item/Ad Updates ---
async function handleItemUpdate(databases, body, log) {
  const { itemId, newTitle, newImageUrl } = body;
  if (!itemId || !newTitle)
    throw new Error('Missing fields for itemUpdate: itemId and newTitle.');

  const documents = await listAllDocuments(databases, [
    Query.equal('relatedItemId', itemId),
  ]);
  if (documents.length === 0) {
    log(`No conversations found for item ${itemId}.`);
    return;
  }

  const updatePromises = documents.map((doc) =>
    databases.updateDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
      doc.$id,
      {
        itemTitle: newTitle,
        itemImageUrl: newImageUrl || doc.itemImageUrl,
      }
    )
  );
  await Promise.all(updatePromises);
  log(`Updated ${documents.length} conversations for item ${itemId}.`);
}

// --- Logic for User Avatar Updates ---
async function handleAvatarUpdate(databases, body, log) {
  const { userId, newAvatarUrl } = body;
  if (!userId) throw new Error('Missing field for avatarUpdate: userId.');

  const documents = await listAllDocuments(databases, [
    Query.equal('participants', [userId]),
  ]);
  if (documents.length === 0) {
    log(`No conversations found for user ${userId}.`);
    return;
  }

  const updatePromises = documents.map((doc) => {
    const participantAvatars = JSON.parse(doc.participantAvatars || '{}');
    participantAvatars[userId] = newAvatarUrl || null;
    return databases.updateDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
      doc.$id,
      { participantAvatars: JSON.stringify(participantAvatars) }
    );
  });
  await Promise.all(updatePromises);
  log(
    `Updated avatar in ${documents.length} conversations for user ${userId}.`
  );
}

// --- Helper for paginating through all documents ---
async function listAllDocuments(databases, queries) {
  let documents = [];
  let cursor = null;
  do {
    const currentQueries = [...queries, Query.limit(100)];
    if (cursor) {
      currentQueries.push(Query.cursorAfter(cursor));
    }
    const response = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
      currentQueries
    );
    if (response.documents.length > 0) {
      documents.push(...response.documents);
      cursor = response.documents[response.documents.length - 1].$id;
    } else {
      cursor = null;
    }
  } while (cursor);
  return documents;
}
