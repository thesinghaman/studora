const { Client, Databases, Query, Permission, Role } = require('node-appwrite');

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

  const { conversationId, userId } = body; // userId is the user READING the messages

  if (!conversationId || !userId) {
    return res.json(
      { success: false, error: 'Missing conversationId or userId.' },
      400
    );
  }

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);

  try {
    // --- Task 1: Find all unread messages sent by the other user ---
    const messageList = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_MESSAGES_COLLECTION_ID,
      [
        Query.equal('conversationId', conversationId),
        Query.notEqual('status', 'read'),
        Query.notEqual('senderId', userId),
      ]
    );

    // --- Task 2: Filter messages to only those the reader has permission to see ---
    const readerPermissionString = `read("user:${userId}")`;
    const messagesReaderCanActuallySee = messageList.documents.filter((doc) =>
      (doc.$permissions || []).includes(readerPermissionString)
    );

    // --- Task 3: Update the conversation's unread count ---
    const conversation = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
      conversationId
    );

    let unreadCounts;
    try {
      unreadCounts = JSON.parse(conversation.unreadCounts || '{}');
    } catch (e) {
      unreadCounts = {};
    }

    const needsCountUpdate = unreadCounts[userId] !== 0;
    if (needsCountUpdate) {
      unreadCounts[userId] = 0;
    }

    // --- Task 4: Execute all updates in parallel ---
    const updatePromises = [];

    // Add conversation update to the promise list if its count needs resetting.
    if (needsCountUpdate) {
      updatePromises.push(
        databases.updateDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
          conversationId,
          { unreadCounts: JSON.stringify(unreadCounts) }
        )
      );
    }

    // Add status updates ONLY for the messages the user was allowed to read.
    for (const message of messagesReaderCanActuallySee) {
      updatePromises.push(
        databases.updateDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_MESSAGES_COLLECTION_ID,
          message.$id,
          { status: 'read' }
        )
      );
    }

    if (updatePromises.length > 0) {
      await Promise.all(updatePromises);
      log(
        `Updated ${messagesReaderCanActuallySee.length} read receipts and reset count for user ${userId} in convo ${conversationId}.`
      );
    } else {
      log(`No updates needed for user ${userId} in convo ${conversationId}.`);
    }

    return res.json({
      success: true,
      message: `Processed read status for ${messagesReaderCanActuallySee.length} messages.`,
    });
  } catch (err) {
    error(`Failed to mark messages as read:`, err);
    return res.json({ success: false, error: err.message }, 500);
  }
};
