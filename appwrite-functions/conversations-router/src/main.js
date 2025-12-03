const {
  Client,
  Databases,
  Storage,
  Query,
  Permission,
  Role,
} = require('node-appwrite');

// Helper function to initialize Appwrite client
const initializeClient = () => {
  return new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
};

// Helper for paginating through all documents
const listAllDocuments = async (databases, queries) => {
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
};

// ==================== UPDATE CONVERSATIONS ====================
const updateConversations = async (body, log, error) => {
  const { type } = body;

  const client = initializeClient();
  const databases = new Databases(client);

  switch (type) {
    case 'itemUpdate':
      return await handleItemUpdate(databases, body, log);

    case 'avatarUpdate':
      return await handleAvatarUpdate(databases, body, log);

    default:
      throw { status: 400, error: 'Invalid update type.' };
  }
};

// Logic for Item/Ad Updates
const handleItemUpdate = async (databases, body, log) => {
  const { itemId, newTitle, newImageUrl } = body;
  if (!itemId || !newTitle)
    throw { status: 400, error: 'Missing fields for itemUpdate: itemId and newTitle.' };

  const documents = await listAllDocuments(databases, [
    Query.equal('relatedItemId', itemId),
  ]);
  if (documents.length === 0) {
    log(`No conversations found for item ${itemId}.`);
    return { success: true, message: 'No conversations to update.' };
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
  return { success: true, message: 'Item update processed.' };
};

// Logic for User Avatar Updates
const handleAvatarUpdate = async (databases, body, log) => {
  const { userId, newAvatarUrl } = body;
  if (!userId) throw { status: 400, error: 'Missing field for avatarUpdate: userId.' };

  const documents = await listAllDocuments(databases, [
    Query.equal('participants', [userId]),
  ]);
  if (documents.length === 0) {
    log(`No conversations found for user ${userId}.`);
    return { success: true, message: 'No conversations to update.' };
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
  return { success: true, message: 'Avatar update processed.' };
};

// ==================== DELETE CONVERSATIONS ====================
const deleteConversations = async (body, log, error) => {
  const { conversationIds, userId } = body;

  if (!conversationIds || !Array.isArray(conversationIds) || !userId) {
    throw { status: 400, error: 'Missing required fields.' };
  }

  const client = initializeClient();
  const databases = new Databases(client);
  const storage = new Storage(client);

  const chatImagesBucketId = process.env.APPWRITE_CHAT_STORAGE_BUCKET_ID;
  if (!chatImagesBucketId) {
    error('Environment variable APPWRITE_CHAT_STORAGE_BUCKET_ID is not set.');
    throw { status: 500, error: 'Server configuration error.' };
  }

  for (const convoId of conversationIds) {
    try {
      // Fetch the conversation document
      const conversation = await databases.getDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        convoId
      );

      // Soft Deletion Logic
      let deletedBy = conversation.deletedBy || [];
      let visibleTo = conversation.visibleTo || [];
      const otherParticipants = conversation.participants.filter(
        (p) => p !== userId
      );

      // Reset the unread count for the deleting user
      const unreadCounts = JSON.parse(conversation.unreadCounts || '{}');

      if (unreadCounts.hasOwnProperty(userId)) {
        log(
          `Resetting unread count for user ${userId} in convo ${convoId} from ${unreadCounts[userId]} to 0 upon deletion.`
        );
        unreadCounts[userId] = 0;
      }

      // Add or update the user's deletion record
      const userRecordIndex = deletedBy.findIndex((recordStr) => {
        try {
          return JSON.parse(recordStr).userId === userId;
        } catch (e) {
          return false;
        }
      });
      const newDeletionRecord = {
        userId: userId,
        deletedAt: new Date().toISOString(),
      };

      if (userRecordIndex !== -1) {
        deletedBy[userRecordIndex] = JSON.stringify(newDeletionRecord);
      } else {
        deletedBy.push(JSON.stringify(newDeletionRecord));
      }
      log(`User ${userId} marked for deletion in convo ${convoId}`);

      // Remove the user from the visibleTo array
      if (visibleTo.includes(userId)) {
        visibleTo = visibleTo.filter((id) => id !== userId);
        log(`User ${userId} removed from visibleTo list for convo ${convoId}.`);
      }

      // Check for Final (Hard) Delete
      const deletedUserIds = new Set(
        deletedBy
          .map((recordStr) => {
            try {
              return JSON.parse(recordStr).userId;
            } catch (e) {
              return null;
            }
          })
          .filter((id) => id)
      );

      const isFinalDelete = otherParticipants.every((p) =>
        deletedUserIds.has(p)
      );

      if (isFinalDelete) {
        // Hard Delete Execution
        log(`Performing final delete for conversation ${convoId}...`);

        // Delete all messages in the conversation
        const messages = await databases.listDocuments(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_MESSAGES_COLLECTION_ID,
          [Query.equal('conversationId', convoId), Query.limit(5000)]
        );
        for (const message of messages.documents) {
          if (message.imageFileIds && Array.isArray(message.imageFileIds)) {
            for (const fileId of message.imageFileIds) {
              try {
                await storage.deleteFile(chatImagesBucketId, fileId);
                log(
                  `Deleted image ${fileId} from bucket ${chatImagesBucketId}`
                );
              } catch (imgErr) {
                error(`Failed to delete image ${fileId}: ${imgErr.message}`);
              }
            }
          }
          await databases.deleteDocument(
            process.env.APPWRITE_DATABASE_ID,
            process.env.APPWRITE_MESSAGES_COLLECTION_ID,
            message.$id
          );
        }
        log(`Deleted ${messages.total} messages for conversation ${convoId}`);

        // Delete the conversation document itself
        await databases.deleteDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
          convoId
        );
        log(`Permanently deleted conversation document ${convoId}`);
      } else {
        // Update document permissions based on the new visibleTo array
        const newPermissions = visibleTo.flatMap((id) => [
          Permission.read(Role.user(id)),
          Permission.update(Role.user(id)),
        ]);

        await databases.updateDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
          convoId,
          { deletedBy, visibleTo, unreadCounts: JSON.stringify(unreadCounts) },
          [...new Set(newPermissions)]
        );
        log(
          `User ${userId} soft-deleted conversation ${convoId}. Updated visibility and permissions.`
        );
      }
    } catch (err) {
      error(
        `Failed to process deletion for conversation ${convoId}: ${err.message}`
      );
    }
  }

  return { success: true, message: 'Deletion process completed.' };
};

// ==================== MAIN ROUTER ====================
module.exports = async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ success: false, error: 'Method not allowed' }, 405);
  }

  let body;
  try {
    body = JSON.parse(req.body);
  } catch (e) {
    return res.json({ success: false, error: 'Invalid JSON body.' }, 400);
  }

  const { action } = body;

  if (!action) {
    return res.json({ success: false, error: 'Missing action parameter.' }, 400);
  }

  try {
    let result;

    switch (action) {
      case 'updateConversations':
        log(`[ROUTER] Executing action: updateConversations`);
        result = await updateConversations(body, log, error);
        return res.json(result);

      case 'deleteConversations':
        log(`[ROUTER] Executing action: deleteConversations`);
        result = await deleteConversations(body, log, error);
        return res.json(result);

      default:
        log(`[ROUTER] Invalid action received: ${action}`);
        return res.json(
          { success: false, error: `Invalid action: ${action}` },
          400
        );
    }
  } catch (err) {
    error(`[ROUTER] Error executing action '${action}': ${err.error || err.message}`);
    return res.json(
      { success: false, error: err.error || err.message },
      err.status || 500
    );
  }
};
