const { Client, Users, Databases, Account } = require('node-appwrite');

module.exports = async ({ req, res, log, error }) => {
  // --- 1. SETUP & CONFIGURATION ---
  const adminClient = new Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_FUNCTION_API_KEY);

  const adminUsers = new Users(adminClient);
  const adminDatabases = new Databases(adminClient);

  // --- 2. INPUT VALIDATION ---
  let payload;
  try {
    payload = JSON.parse(req.body);
  } catch (err) {
    error('Invalid JSON payload.', err);
    return res.json(
      { success: false, message: 'Bad Request: Invalid JSON payload.' },
      400
    );
  }

  const { userIdToDelete, jwt } = payload;
  if (!userIdToDelete || typeof userIdToDelete !== 'string') {
    return res.json(
      { success: false, message: 'Bad Request: `userIdToDelete` is required.' },
      400
    );
  }
  if (!jwt || typeof jwt !== 'string') {
    return res.json(
      { success: false, message: 'Bad Request: `jwt` is required.' },
      400
    );
  }

  // --- 3. AUTHORIZATION & VERIFICATION ---
  try {
    // This client is authenticated AS THE USER using the provided JWT.
    const userClient = new Client()
      .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
      .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
      .setJWT(jwt);

    const userAccount = new Account(userClient);
    const user = await userAccount.get(); // Verify the JWT is valid by fetching the user.

    // Security Check: Ensure the JWT belongs to the user they are trying to delete.
    if (user.$id !== userIdToDelete) {
      error(
        `SECURITY ALERT: JWT for user ${user.$id} was used to attempt deletion of user ${userIdToDelete}.`
      );
      return res.json(
        {
          success: false,
          message: 'Forbidden: JWT does not match the user ID.',
        },
        403
      );
    }

    // Security Check: Ensure the account is not verified.
    if (user.emailVerification) {
      log(
        `SECURITY WARNING: Attempted to delete a VERIFIED user (${userIdToDelete}). Operation blocked.`
      );
      return res.json(
        {
          success: false,
          message: 'Bad Request: Cannot delete a verified user account.',
        },
        400
      );
    }

    log(
      `SUCCESS: JWT validated for unverified user ${user.$id}. Proceeding with deletion.`
    );

    // --- 4. CORE DELETION LOGIC ---
    // Delete the database document.
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

    // Delete the auth user.
    await adminUsers.delete(userIdToDelete);
    log(`SUCCESS: Deleted auth record for user ${userIdToDelete}.`);

    return res.json({ success: true, message: 'Account permanently deleted.' });
  } catch (err) {
    error(
      `FATAL ERROR during deletion process for user ${userIdToDelete}: ${err.message}`
    );
    // Check if the error is from an invalid JWT.
    if (err.type === 'user_jwt_invalid') {
      return res.json(
        {
          success: false,
          message:
            'Forbidden: The provided session token is invalid or expired.',
        },
        401
      );
    }
    return res.json(
      { success: false, message: 'An internal server error occurred.' },
      500
    );
  }
};
