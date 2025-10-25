const {
  Client,
  Databases,
  Storage,
  Query,
  Permission,
  Role,
} = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  const { conversationIds, userId } = JSON.parse(req.body);

  // 1. --- Input Validation ---
  if (!conversationIds || !Array.isArray(conversationIds) || !userId) {
    return res.json({ success: false, error: 'Missing required fields.' }, 400);
  }

  // 2. --- Appwrite Client Initialization ---
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);
  const storage = new Storage(client);

  // 3. --- Environment Variable Check ---
  const chatImagesBucketId = process.env.APPWRITE_CHAT_STORAGE_BUCKET_ID;
  if (!chatImagesBucketId) {
    error('Environment variable APPWRITE_CHAT_STORAGE_BUCKET_ID is not set.');
    return res.json(
      { success: false, error: 'Server configuration error.' },
      500
    );
  }

  // 4. --- Process Deletion for each Conversation ID ---
  for (const convoId of conversationIds) {
    try {
      // Fetch the conversation document
      const conversation = await databases.getDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        convoId
      );

      // --- Soft Deletion Logic ---
      let deletedBy = conversation.deletedBy || [];
      let visibleTo = conversation.visibleTo || [];
      const otherParticipants = conversation.participants.filter(
        (p) => p !== userId
      );

      // Reset the unread count for the deleting user.
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

      // --- Check for Final (Hard) Delete ---
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
        // --- Hard Delete Execution ---
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
          [...new Set(newPermissions)] // Set the new, restricted permissions
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

  // 5. --- Return Success Response ---
  return res.json({ success: true, message: 'Deletion process completed.' });
};
