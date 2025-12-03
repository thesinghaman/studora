const {
  Client,
  Databases,
  Permission,
  Role,
  ID,
  Query,
  Functions,
  Messaging,
} = require('node-appwrite');

// Helper function to initialize Appwrite client
const initializeClient = () => {
  return new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
};

// ==================== CREATE MESSAGE ====================
const createMessage = async (body, log, error) => {
  let {
    conversationId,
    senderId,
    text,
    participants,
    messageType,
    imageUrls,
    imageFileIds,
    relatedItem,
    participantNames,
    participantAvatars,
  } = body;

  if (
    !senderId ||
    !participants ||
    !Array.isArray(participants) ||
    participants.length < 2
  ) {
    throw {
      status: 400,
      error: 'Missing or invalid fields (senderId, participants).',
    };
  }
  if (!text && (!imageUrls || imageUrls.length === 0)) {
    throw { status: 400, error: 'Message must contain text or images.' };
  }

  participants.sort();

  const client = initializeClient();
  const databases = new Databases(client);
  const functions = new Functions(client);
  const recipientId = participants.find((p) => p !== senderId);

  // Find existing conversation if ID is not provided
  if (!conversationId) {
    log(
      `No conversationId. Finding by participants: ${participants.join(', ')}`
    );
    try {
      const queries = participants.map((id) =>
        Query.contains('participants', id)
      );
      const response = await databases.listDocuments(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        queries
      );
      const exactMatch = response.documents.find((doc) => {
        const docParticipants = [...doc.participants].sort();
        return (
          docParticipants.length === participants.length &&
          docParticipants.every((p, i) => p === participants[i])
        );
      });
      if (exactMatch) {
        log(
          `Found existing conversation: ${exactMatch.$id}. Will update this conversation.`
        );
        conversationId = exactMatch.$id;
      } else {
        log('No existing conversation found. Will create a new one.');
      }
    } catch (e) {
      error(
        `Error searching for conversation: ${e.message}. Proceeding to create.`
      );
    }
  }

  // Check Block Status
  let isSenderBlocked = false;
  if (recipientId) {
    try {
      const recipientDoc = await databases.getDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_USERS_COLLECTION_ID,
        recipientId
      );
      isSenderBlocked = (recipientDoc.blockedUsers || []).includes(senderId);
    } catch (e) {
      error(
        `CRITICAL: Could not check block status for recipient ${recipientId}. Error: ${e.message}`
      );
      throw {
        status: 500,
        error: 'Could not verify recipient permissions.',
      };
    }
  }

  const timestamp = new Date().toISOString();
  const snippet =
    messageType === 'image'
      ? imageUrls?.length > 1
        ? `📷 ${imageUrls.length} Images`
        : '📷 Image'
      : text;

  // Create or Update Conversation Document
  try {
    if (conversationId) {
      // CONVERSATION EXISTS: HEAL AND UPDATE (WITH BLOCK CHECK)
      const conversationDoc = await databases.getDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        conversationId
      );
      let visibleTo = conversationDoc.visibleTo || [];
      let deletedBy = conversationDoc.deletedBy || [];
      let permissionsUpdated = false;
      let newPermissions = [...conversationDoc.$permissions];

      // Heal visibility and permissions, RESPECTING BLOCK STATUS
      for (const pId of participants) {
        if (!visibleTo.includes(pId)) {
          // Do NOT add the recipient back to visibility if they have blocked the sender.
          if (pId === recipientId && isSenderBlocked) {
            log(
              `Sender ${senderId} is blocked by recipient ${recipientId}. NOT re-adding to visibleTo.`
            );
            continue;
          }

          visibleTo.push(pId);
          if (
            !newPermissions.some((p) => p.startsWith(`read("user:${pId}")`))
          ) {
            newPermissions.push(
              Permission.read(Role.user(pId)),
              Permission.update(Role.user(pId))
            );
            permissionsUpdated = true;
          }
        }
      }

      const currentUnreadCounts = JSON.parse(
        conversationDoc.unreadCounts || '{}'
      );
      if (!isSenderBlocked && recipientId) {
        currentUnreadCounts[recipientId] =
          (currentUnreadCounts[recipientId] || 0) + 1;
      }

      await databases.updateDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        conversationId,
        {
          lastMessageTimestamp: timestamp,
          lastMessageSenderId: senderId,
          lastMessageSnippet: snippet,
          unreadCounts: JSON.stringify(currentUnreadCounts),
          visibleTo,
          deletedBy,
        },
        permissionsUpdated ? [...new Set(newPermissions)] : undefined
      );
      log(`Successfully updated conversation ${conversationId}.`);
    } else {
      // NEW CONVERSATION: CREATE WITH ALL FIELDS (WITH BLOCK CHECK)
      log(`Creating new conversation.`);
      const conversationData = {
        participants,
        participantNames: JSON.stringify(participantNames || {}),
        participantAvatars: JSON.stringify(participantAvatars || {}),
        lastMessageTimestamp: timestamp,
        unreadCounts: JSON.stringify({
          [senderId]: 0,
          [recipientId]: isSenderBlocked ? 0 : 1,
        }),
        lastMessageSenderId: senderId,
        lastMessageSnippet: snippet,
        relatedItemId: relatedItem?.id || null,
        itemType: relatedItem?.type || null,
        itemTitle: relatedItem?.title || null,
        itemImageUrl: relatedItem?.imageUrl || null,
        deletedBy: [],
        visibleTo: isSenderBlocked ? [senderId] : participants,
      };

      const permissions = isSenderBlocked
        ? [
            Permission.read(Role.user(senderId)),
            Permission.update(Role.user(senderId)),
          ]
        : participants.flatMap((id) => [
            Permission.read(Role.user(id)),
            Permission.update(Role.user(id)),
          ]);

      const newConversationDoc = await databases.createDocument(
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_CONVERSATIONS_COLLECTION_ID,
        ID.unique(),
        conversationData,
        [...new Set(permissions)]
      );
      conversationId = newConversationDoc.$id;
      log(`Successfully created new conversation ${conversationId}.`);
    }
  } catch (e) {
    error(`Failed during conversation create/update: ${e.message}`);
    throw { status: 500, error: 'Failed to process conversation.' };
  }

  // Create the Message Document
  try {
    const messageData = {
      conversationId,
      senderId,
      text: text || null,
      imageUrls: imageUrls || null,
      imageFileIds: imageFileIds || null,
      timestamp: timestamp,
      messageType: messageType,
      status: 'sent',
    };

    const messagePermissions = isSenderBlocked
      ? [
          Permission.read(Role.user(senderId)),
          Permission.update(Role.user(senderId)),
          Permission.delete(Role.user(senderId)),
        ]
      : participants.flatMap((id) => [
          Permission.read(Role.user(id)),
          Permission.update(Role.user(id)),
          Permission.delete(Role.user(id)),
        ]);

    const messageDoc = await databases.createDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_MESSAGES_COLLECTION_ID,
      ID.unique(),
      messageData,
      [...new Set(messagePermissions)]
    );
    log(
      `Successfully created message ${messageDoc.$id} in conversation ${conversationId}`
    );

    // Trigger Notification (inline instead of separate function call)
    if (!isSenderBlocked) {
      try {
        // Environment validation
        if (
          !process.env.APPWRITE_ENDPOINT ||
          !process.env.APPWRITE_PROJECT_ID ||
          !process.env.APPWRITE_API_KEY ||
          !process.env.APPWRITE_DATABASE_ID ||
          !process.env.APPWRITE_USERS_COLLECTION_ID
        ) {
          error('❌ Environment variables missing for notification.');
        } else {
          const messaging = new Messaging(client);
          
          // Fetch sender's information
          const senderUserDoc = await databases.getDocument(
            process.env.APPWRITE_DATABASE_ID,
            process.env.APPWRITE_USERS_COLLECTION_ID,
            senderId
          );
          const senderName = senderUserDoc.name || 'Someone';
          
          // Send push notification
          const pushResponse = await messaging.createPush(
            ID.unique(),
            `New Message from ${senderName}`,
            messageType === 'image' ? '📷 Sent you an image' : text,
            { conversationId, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
            [],
            [recipientId],
            []
          );
          
          log(
            `✅ Push notification queued successfully! Delivery ID: ${pushResponse.$id}`
          );
        }
      } catch (notifyError) {
        error(
          `Failed to send notification for message ${messageDoc.$id}: ${notifyError.message}`
        );
      }
    } else {
      log(
        `Skipping notification for message ${messageDoc.$id} because sender is blocked.`
      );
    }

    return { success: true, data: messageDoc };
  } catch (err) {
    error(`Failed to create message document: ${err.message}`);
    throw { status: 500, error: err.message };
  }
};

// ==================== MARK MESSAGES AS READ ====================
const markMessagesAsRead = async (body, log, error) => {
  const { conversationId, userId } = body;

  if (!conversationId || !userId) {
    throw { status: 400, error: 'Missing conversationId or userId.' };
  }

  const client = initializeClient();
  const databases = new Databases(client);

  try {
    // Find all unread messages sent by the other user
    const messageList = await databases.listDocuments(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_MESSAGES_COLLECTION_ID,
      [
        Query.equal('conversationId', conversationId),
        Query.notEqual('status', 'read'),
        Query.notEqual('senderId', userId),
      ]
    );

    // Filter messages to only those the reader has permission to see
    const readerPermissionString = `read("user:${userId}")`;
    const messagesReaderCanActuallySee = messageList.documents.filter((doc) =>
      (doc.$permissions || []).includes(readerPermissionString)
    );

    // Update the conversation's unread count
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

    // Execute all updates in parallel
    const updatePromises = [];

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

    return {
      success: true,
      message: `Processed read status for ${messagesReaderCanActuallySee.length} messages.`,
    };
  } catch (err) {
    error(`Failed to mark messages as read:`, err);
    throw { status: 500, error: err.message };
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
      case 'createMessage':
        log(`[ROUTER] Executing action: createMessage`);
        result = await createMessage(body, log, error);
        return res.json(result);

      case 'markMessagesAsRead':
        log(`[ROUTER] Executing action: markMessagesAsRead`);
        result = await markMessagesAsRead(body, log, error);
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
