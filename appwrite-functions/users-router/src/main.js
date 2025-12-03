const {
  Client,
  Account,
  Databases,
  Storage,
  Query,
  Users,
} = require('node-appwrite');

// Helper function to initialize Appwrite client
const initializeClient = () => {
  return new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
};

// Helper function to delete images for a document
const deleteImagesForDocument = async (doc, storage, bucketId, log, error) => {
  const fileIdsToDelete = new Set();

  // Use the direct file IDs if available
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
  // If no file IDs, fall back to parsing URLs
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
    return;
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

// ==================== GET USER PROFILE ====================
const getUserProfile = async (body, log, error) => {
  const { targetUserId } = body;
  if (!targetUserId) {
    throw { status: 400, message: 'Missing required field: targetUserId.' };
  }

  const requestingUserId = body.requestingUserId;
  if (!requestingUserId) {
    throw { status: 401, message: 'Authentication required.' };
  }

  const client = initializeClient();
  const databases = new Databases(client);

  try {
    // Fetch the document of the user being viewed (the target)
    const targetUserDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      targetUserId
    );

    // Check if the requesting user is in the target's block list
    const blockedUsers = targetUserDoc.blockedUsers || [];
    const isRequesterBlocked = blockedUsers.includes(requestingUserId);

    // Prepare the response based on the block status
    let userProfile;

    if (isRequesterBlocked) {
      // If blocked, return a minimal profile with no sensitive data
      log(`Request from blocked user ${requestingUserId} to ${targetUserId}.`);
      userProfile = {
        userId: targetUserDoc.$id,
        userName: targetUserDoc.userName,
        userAvatarUrl: null,
        email: 'private',
        rollNumber: 'private',
        hostel: null,
        isOnline: false,
        lastSeen: null,
        dateJoined: null,
        isBlocked: true,
      };
    } else {
      // If not blocked, return the full public profile details
      log(`Request from user ${requestingUserId} to ${targetUserId}.`);
      userProfile = {
        userId: targetUserDoc.$id,
        userName: targetUserDoc.userName,
        userAvatarUrl: targetUserDoc.userAvatarUrl,
        email: targetUserDoc.email,
        rollNumber: targetUserDoc.rollNumber,
        hostel: targetUserDoc.hostel,
        dateJoined: targetUserDoc.dateJoined,
        isBlocked: false,
        isOnline: targetUserDoc.showLastSeen ? targetUserDoc.isOnline : false,
        lastSeen: targetUserDoc.showLastSeen ? targetUserDoc.lastSeen : null,
        showReadReceipts: targetUserDoc.showReadReceipts,
      };
    }

    return { success: true, data: userProfile };
  } catch (e) {
    error(`Error fetching user profile for ${targetUserId}: ${e}`);
    if (e.code === 404) {
      throw { status: 404, message: 'User not found.' };
    }
    throw { status: 500, message: 'An error occurred on the server.' };
  }
};

// ==================== DELETE USER ACCOUNT ====================
const deleteUserAccount = async (body, log, error) => {
  const { userId, password } = body;

  if (!userId || !password) {
    throw {
      status: 400,
      message: 'User ID and password are required.',
    };
  }

  const client = initializeClient();
  const account = new Account(client);
  const databases = new Databases(client);
  const storage = new Storage(client);
  const users = new Users(client);

  try {
    // Verify Password
    const userDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      userId
    );
    const email = userDoc.email;
    await account.createEmailPasswordSession(email, password);
    log(`Password verified for user ${userId}. Starting deletion process.`);

    // Delete Profile Picture (Avatar)
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

    // Delete User's Ads (Items) and Their Images
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

    // Delete User's Lost & Found Posts and Their Images
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

    // Mark User's Conversations as Deleted
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

    // Delete User's Profile Document
    await databases.deleteDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      userId
    );
    log(`Deleted user profile document ${userId}.`);

    // Delete Auth User
    await users.delete(userId);
    log(`Successfully deleted auth user ${userId}.`);

    return {
      success: true,
      message: 'User account deleted successfully.',
    };
  } catch (err) {
    error(`A controlled error occurred during user deletion: ${err.message}`);
    if (
      err.type === 'user_invalid_credentials' ||
      err.message.toLowerCase().includes('invalid credentials')
    ) {
      throw {
        status: 401,
        message: 'Incorrect password. Please try again.',
      };
    }
    throw {
      status: 500,
      message: 'A server error occurred during account deletion.',
    };
  }
};

// ==================== DELETE UNVERIFIED USER ====================
const deleteUnverifiedUser = async (body, log, error) => {
  const { userIdToDelete, jwt } = body;

  if (!userIdToDelete || typeof userIdToDelete !== 'string') {
    throw { status: 400, message: 'Bad Request: `userIdToDelete` is required.' };
  }
  if (!jwt || typeof jwt !== 'string') {
    throw { status: 400, message: 'Bad Request: `jwt` is required.' };
  }

  const adminClient = initializeClient();
  const adminUsers = new Users(adminClient);
  const adminDatabases = new Databases(adminClient);

  try {
    // This client is authenticated AS THE USER using the provided JWT
    const userClient = new Client()
      .setEndpoint(process.env.APPWRITE_ENDPOINT)
      .setProject(process.env.APPWRITE_PROJECT_ID)
      .setJWT(jwt);

    const userAccount = new Account(userClient);
    const user = await userAccount.get();

    // Security Check: Ensure the JWT belongs to the user they are trying to delete
    if (user.$id !== userIdToDelete) {
      error(
        `SECURITY ALERT: JWT for user ${user.$id} was used to attempt deletion of user ${userIdToDelete}.`
      );
      throw {
        status: 403,
        message: 'Forbidden: JWT does not match the user ID.',
      };
    }

    // Security Check: Ensure the account is not verified
    if (user.emailVerification) {
      log(
        `SECURITY WARNING: Attempted to delete a VERIFIED user (${userIdToDelete}). Operation blocked.`
      );
      throw {
        status: 400,
        message: 'Bad Request: Cannot delete a verified user account.',
      };
    }

    log(
      `SUCCESS: JWT validated for unverified user ${user.$id}. Proceeding with deletion.`
    );

    // Delete the database document
    try {
      await adminDatabases.deleteDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_USERS_COLLECTION_ID,
        userIdToDelete
      );
      log(`SUCCESS: Deleted database profile for user ${userIdToDelete}.`);
    } catch (err) {
      if (err.code !== 404) throw err;
      log(
        `INFO: Database profile for user ${userIdToDelete} was already deleted.`
      );
    }

    // Delete the auth user
    await adminUsers.delete(userIdToDelete);
    log(`SUCCESS: Deleted auth record for user ${userIdToDelete}.`);

    return { success: true, message: 'Account permanently deleted.' };
  } catch (err) {
    error(
      `FATAL ERROR during deletion process for user ${userIdToDelete}: ${err.message}`
    );
    // Check if the error is from an invalid JWT
    if (err.type === 'user_jwt_invalid') {
      throw {
        status: 401,
        message:
          'Forbidden: The provided session token is invalid or expired.',
      };
    }
    throw { status: 500, message: 'An internal server error occurred.' };
  }
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
      case 'getUserProfile':
        log(`[ROUTER] Executing action: getUserProfile`);
        result = await getUserProfile(body, log, error);
        return res.json(result);

      case 'deleteUserAccount':
        log(`[ROUTER] Executing action: deleteUserAccount`);
        result = await deleteUserAccount(body, log, error);
        return res.json(result);

      case 'deleteUnverifiedUser':
        log(`[ROUTER] Executing action: deleteUnverifiedUser`);
        result = await deleteUnverifiedUser(body, log, error);
        return res.json(result);

      default:
        log(`[ROUTER] Invalid action received: ${action}`);
        return res.json(
          { success: false, error: `Invalid action: ${action}` },
          400
        );
    }
  } catch (err) {
    error(`[ROUTER] Error executing action '${action}': ${err.message || err.error}`);
    return res.json(
      { success: false, error: err.message || err.error || 'Internal server error' },
      err.status || 500
    );
  }
};
