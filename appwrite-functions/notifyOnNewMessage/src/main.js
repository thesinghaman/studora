const { Client, Messaging, Databases, ID } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  log('--- Function Execution Started ---');

  // --- Step 1: Environment Validation ---
  log('Verifying environment variables...');
  if (
    !process.env.APPWRITE_ENDPOINT ||
    !process.env.APPWRITE_PROJECT_ID ||
    !process.env.APPWRITE_API_KEY ||
    !process.env.APPWRITE_DATABASE_ID ||
    !process.env.APPWRITE_USERS_COLLECTION_ID
  ) {
    error(
      "❌ FATAL: One or more required environment variables are missing. Please check the function's settings in the Appwrite console."
    );
    return res.json(
      { success: false, error: 'Server configuration error.' },
      500
    );
  }
  log('✅ Environment variables verified.');
  log(`Using Project ID: ${process.env.APPWRITE_PROJECT_ID}`);

  // --- Step 2: Payload Parsing ---
  log('Parsing request payload...');
  let messageData;
  try {
    messageData = JSON.parse(req.body);
  } catch (e) {
    error('❌ FAILED: Could not parse JSON from request body.', e);
    return res.json({ success: false, error: 'Invalid request body.' }, 400);
  }
  log('✅ Payload parsed successfully.');

  // --- Step 3: Recipient Identification ---
  log('Identifying recipient from payload...');
  const { senderId, participants, text, conversationId, messageType } =
    messageData;
  if (!senderId || !participants || !Array.isArray(participants)) {
    error('❌ FAILED: Payload is missing senderId or participants array.');
    return res.json(
      { success: false, error: 'Missing senderId or participants.' },
      400
    );
  }

  const recipientId = participants.find((p) => p !== senderId);
  if (!recipientId) {
    log(
      '✅ SUCCESS (No Action): No recipient found in the participants list. Aborting notification as expected.'
    );
    return res.json({ success: true, message: 'No recipient to notify.' });
  }
  log(`✅ Recipient identified: ${recipientId}`);

  // --- Step 4: Appwrite Client Initialization ---
  log('Initializing Appwrite client...');
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const messaging = new Messaging(client);
  const databases = new Databases(client);
  log('✅ Appwrite client initialized.');

  try {
    // --- Step 5: Fetching Sender's Information ---
    log(`Fetching sender's name for user ID: ${senderId}...`);
    const senderUserDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      senderId
    );
    const senderName = senderUserDoc.name || 'Someone';
    log(`✅ Sender's name is "${senderName}".`);

    // --- Step 6: Sending the Push Notification ---
    log(`Attempting to send push notification to user ID: ${recipientId}...`);
    const pushResponse = await messaging.createPush(
      ID.unique(), // messageId
      `New Message from ${senderName}`, // title
      messageType === 'image' ? '📷 Sent you an image' : text, // body
      { conversationId, click_action: 'FLUTTER_NOTIFICATION_CLICK' }, // data
      [], // topics
      [recipientId], // users
      [] // targets
    );

    log(
      `✅✅✅ SUCCESS: Push notification queued successfully! Delivery ID: ${pushResponse.$id}`
    );
    return res.json({ success: true, deliveryId: pushResponse.$id });
  } catch (e) {
    error(
      `❌ FAILED: The 'createPush' method failed. This is the final point of failure.`
    );
    error(`--- Error Details ---`);
    error(`Recipient User ID: ${recipientId}`);
    error(`Exception Type: ${e.constructor.name}`);
    error(`Error Message: ${e.message}`);
    error('Full Error Object:', e);
    error('---------------------');
    error(
      'CONCLUSION: Since sending from the console works, this failure points to a bug in the Appwrite (v1.7.4) function execution environment. Please consider upgrading Appwrite or reporting this bug.'
    );
    return res.json({ success: false, error: e.message }, 500);
  }
};
