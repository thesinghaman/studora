const {
  Client,
  Databases,
  Permission,
  Role,
  ID,
  Query,
  Functions,
} = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  // 1. --- Input Validation & Initialization ---
  if (req.method !== 'POST') {
    return res.json({ success: false, error: 'Method not allowed' }, 405);
  }
  let body;
  try {
    body = JSON.parse(req.body);
  } catch (e) {
    return res.json({ success: false, error: 'Invalid JSON body.' }, 400);
  }
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
    return res.json(
      {
        success: false,
        error: 'Missing or invalid fields (senderId, participants).',
      },
      400
    );
  }
  if (!text && (!imageUrls || imageUrls.length === 0)) {
    return res.json(
      { success: false, error: 'Message must contain text or images.' },
      400
    );
  }

  participants.sort();

  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const databases = new Databases(client);
  const functions = new Functions(client);
  const recipientId = participants.find((p) => p !== senderId);

  // 2. --- Find Existing Conversation if ID is not provided ---
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

  // 3. --- Check Block Status ---
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
      return res.json(
        { success: false, message: 'Could not verify recipient permissions.' },
        500
      );
    }
  }

  const timestamp = new Date().toISOString();
  const snippet =
    messageType === 'image'
      ? imageUrls?.length > 1
        ? `📷 ${imageUrls.length} Images`
        : '📷 Image'
      : text;

  // 4. --- Create or Update Conversation Document ---
  try {
    if (conversationId) {
      // --- CONVERSATION EXISTS: HEAL AND UPDATE (WITH BLOCK CHECK) ---
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
            continue; // Skip to the next participant
          }

          // Otherwise, heal the conversation for this user
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
        // Only increment if not blocked
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
      // --- NEW CONVERSATION: CREATE WITH ALL FIELDS (WITH BLOCK CHECK) ---
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
    return res.json(
      { success: false, error: 'Failed to process conversation.' },
      500
    );
  }

  // 5. --- Create the Message Document ---
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

    // Grant permissions for the message document
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

    // 6. --- Trigger Notification ---
    if (!isSenderBlocked) {
      try {
        const notifyPayload = JSON.stringify({
          ...messageDoc,
          participants, // Pass the participants list to the notification function
        });

        await functions.createExecution(
          process.env.APPWRITE_NOTIFY_ON_NEW_MESSAGE_FUNCTION_ID,
          notifyPayload,
          false
        );
        log(
          `Successfully triggered notification for message ${messageDoc.$id}`
        );
      } catch (notifyError) {
        error(
          `Failed to trigger notification for message ${messageDoc.$id}: ${notifyError.message}`
        );
      }
    } else {
      log(
        `Skipping notification for message ${messageDoc.$id} because sender is blocked.`
      );
    }

    return res.json({ success: true, data: messageDoc });
  } catch (err) {
    error(`Failed to create message document: ${err.message}`);
    return res.json({ success: false, error: err.message }, 500);
  }
};
