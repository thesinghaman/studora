const { Client, Databases } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  // 1. Validate the request
  if (req.method !== 'POST') {
    return res.json({ success: false, message: 'Method not allowed' }, 405);
  }

  let body;
  try {
    body = JSON.parse(req.body);
  } catch (e) {
    return res.json({ success: false, message: 'Invalid JSON body.' }, 400);
  }

  const { targetUserId } = body;
  if (!targetUserId) {
    return res.json(
      { success: false, message: 'Missing required field: targetUserId.' },
      400
    );
  }

  // 2. Get the authenticated user who is making the request
  const requestingUserId = req.headers['x-appwrite-user-id'];
  if (!requestingUserId) {
    return res.json(
      { success: false, message: 'Authentication required.' },
      401
    );
  }

  // 3. Initialize the Appwrite server-side client
  const client = new Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new Databases(client);

  try {
    // 4. Fetch the document of the user being viewed (the target)
    const targetUserDoc = await databases.getDocument(
      process.env.APPWRITE_DATABASE_ID,
      process.env.APPWRITE_USERS_COLLECTION_ID,
      targetUserId
    );

    // 5. Check if the requesting user is in the target's block list
    const blockedUsers = targetUserDoc.blockedUsers || [];
    const isRequesterBlocked = blockedUsers.includes(requestingUserId);

    // 6. Prepare the response based on the block status
    let userProfile;

    if (isRequesterBlocked) {
      // If blocked, return a minimal profile with no sensitive data
      log(`Request from blocked user ${requestingUserId} to ${targetUserId}.`);
      userProfile = {
        userId: targetUserDoc.$id,
        userName: targetUserDoc.userName,
        userAvatarUrl: null,
        email: 'private', // Mask sensitive data
        rollNumber: 'private',
        hostel: null,
        isOnline: false, // Always return false
        lastSeen: null, // Always return null
        dateJoined: null,
        isBlocked: true, // Crucial flag for the client app
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

    return res.json({ success: true, data: userProfile });
  } catch (e) {
    error(`Error fetching user profile for ${targetUserId}: ${e}`);
    if (e.code === 404) {
      return res.json({ success: false, message: 'User not found.' }, 404);
    }
    return res.json(
      { success: false, message: 'An error occurred on the server.' },
      500
    );
  }
};
