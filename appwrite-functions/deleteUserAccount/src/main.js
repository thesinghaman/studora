const {
  Client,
  Account,
  Databases,
  Storage,
  Query,
  Users,
} = require('node-appwrite');

const deleteImagesForDocument = async (doc, storage, bucketId, log, error) => {
  const fileIdsToDelete = new Set();

  // 1. Use the direct file IDs if available.
  if (
    doc.imageFileIds &&
    Array.isArray(doc.imageFileIds) &&
    doc.imageFileIds.length > 0
  ) {
    log(
      `Found ${doc.imageFileIds.length} direct file IDs in 'imageFileIds' for document ${doc.$id}.`
    );
    doc.imageFileIds.forEach((id) => fileIdsToDelete.add(id));
  }
  // 2. If no file IDs, fall back to parsing URLs.
  else if (
    doc.imageUrls &&
    Array.isArray(doc.imageUrls) &&
    doc.imageUrls.length > 0
  ) {
    log(
      `No 'imageFileIds' found for ${doc.$id}. Parsing ${doc.imageUrls.length} URLs from 'imageUrls'.`
    );
    for (const url of doc.imageUrls) {
      try {
        const parts = url.split('/files/');
        if (parts.length > 1) {
          const fileId = parts[1].split('/')[0];
          if (fileId) {
            fileIdsToDelete.add(fileId);
          }
        }
      } catch (parseErr) {
        error(
          `Failed to parse file ID from URL "${url}". Error: ${parseErr.message}`
        );
      }
    }
  }

  if (fileIdsToDelete.size === 0) {
    return; // Nothing to delete
  }

  log(
    `Attempting to delete ${fileIdsToDelete.size} unique image(s) for document ${doc.$id}...`
  );
  const deletePromises = Array.from(fileIdsToDelete).map((fileId) =>
    storage.deleteFile(bucketId, fileId).catch((e) => {
      if (e.code !== 404) {
        error(`Failed to delete image file ${fileId}: ${e.message}`);
      }
    })
  );
  await Promise.all(deletePromises);
  log(`Image deletion process completed for document ${doc.$id}.`);
};

module.exports = async ({ req, res, log, error }) => {
  const { userId, password } = JSON.parse(req.body);

  if (!userId || !password) {
    return res.json({
      success: false,
      message: 'User ID and password are required.',
    });
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const account = new Account(client);
  const databases = new Databases(client);
  const storage = new Storage(client);
  const users = new Users(client);

  try {
    // 1. Verify Password
    const userDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      userId
    );
    const email = userDoc.email;
    await account.createEmailPasswordSession(email, password);
    log(`Password verified for user ${userId}. Starting deletion process.`);

    // 2. Delete Profile Picture (Avatar)
    if (userDoc.userAvatarFileId) {
      try {
        await storage.deleteFile(
          process.env.APPWRITE_AVATARS_BUCKET_ID,
          userDoc.userAvatarFileId
        );
        log(`Deleted avatar ${userDoc.userAvatarFileId}.`);
      } catch (e) {
        if (e.code !== 404)
          error(
            `Could not delete avatar ${userDoc.userAvatarFileId}: ${e.message}`
          );
      }
    }

    // 3. Delete User's Ads (Items) and Their Images
    let hasMoreItems = true;
    while (hasMoreItems) {
      const userItems = await databases.listDocuments(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_ITEMS_COLLECTION_ID,
        [Query.equal('sellerId', userId), Query.limit(100)]
      );
      hasMoreItems = userItems.documents.length === 100;
      for (const item of userItems.documents) {
        await deleteImagesForDocument(
          item,
          storage,
          process.env.APPWRITE_ITEMS_BUCKET_ID,
          log,
          error
        );
        await databases.deleteDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_ITEMS_COLLECTION_ID,
          item.$id
        );
      }
      if (userItems.documents.length > 0)
        log(
          `Processed a batch of ${userItems.documents.length} ad items for deletion.`
        );
    }

    // 4. Delete User's Lost & Found Posts and Their Images
    let hasMoreLFItems = true;
    while (hasMoreLFItems) {
      const userLFItems = await databases.listDocuments(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_LOSTFOUND_COLLECTION_ID,
        [Query.equal('reporterId', userId), Query.limit(100)]
      );
      hasMoreLFItems = userLFItems.documents.length === 100;
      for (const item of userLFItems.documents) {
        await deleteImagesForDocument(
          item,
          storage,
          process.env.APPWRITE_ITEMS_BUCKET_ID,
          log,
          error
        );
        await databases.deleteDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_LOSTFOUND_COLLECTION_ID,
          item.$id
        );
      }
      if (userLFItems.documents.length > 0)
        log(
          `Processed a batch of ${userLFItems.documents.length} L&F posts for deletion.`
        );
    }

    // 5. Mark User's Conversations as Deleted
    const userConversations = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
      [Query.contains('participants', userId), Query.limit(5000)]
    );
    for (const convo of userConversations.documents) {
      let deletedBy = convo.deletedBy || [];
      const newDeletionRecord = JSON.stringify({
        userId: userId,
        deletedAt: new Date().toISOString(),
      });
      const userRecordIndex = deletedBy.findIndex((recordStr) => {
        try {
          return JSON.parse(recordStr).userId === userId;
        } catch (e) {
          return false;
        }
      });
      if (userRecordIndex === -1) {
        deletedBy.push(newDeletionRecord);
        await databases.updateDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
          convo.$id,
          { deletedBy }
        );
      }
    }
    log(
      `Marked ${userConversations.total} conversations as deleted for user ${userId}.`
    );

    // 6. Delete User's Profile Document
    await databases.deleteDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      userId
    );
    log(`Deleted user profile document ${userId}.`);

    // 7. Delete Auth User
    await users.delete(userId);
    log(`Successfully deleted auth user ${userId}.`);

    return res.json({
      success: true,
      message: 'User account deleted successfully.',
    });
  } catch (err) {
    error(`A controlled error occurred during user deletion: ${err.message}`);
    if (
      err.type === 'user_invalid_credentials' ||
      err.message.toLowerCase().includes('invalid credentials')
    ) {
      return res.json({
        success: false,
        message: 'Incorrect password. Please try again.',
      });
    }
    return res.json({
      success: false,
      message: 'A server error occurred during account deletion.',
    });
  }
};
