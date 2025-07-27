import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class AuthProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  static const String className = 'AuthProvider';
  static const String _appVerificationWebUrl = 'https://studora.shop/verify';
  static const String _appPasswordResetWebUrl = 'https://studora.shop/recover';
  Future<appwrite_models.File> uploadProfilePicture(
    String userId,
    File image,
  ) async {
    return _appwriteService.storage.createFile(
      bucketId: AppConstants.itemsImagesBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(
        path: image.path,
        filename: 'avatar_$userId.jpg',
      ),
      permissions: [
        Permission.read(Role.any()),
      ],
    );
  }
  Future<void> deleteProfilePicture(String fileId) async {
    try {
      await _appwriteService.storage.deleteFile(
        bucketId: AppConstants.itemsImagesBucketId,
        fileId: fileId,
      );
    } on AppwriteException catch (e) {
      if (e.code != 404) {
        rethrow;
      }
    }
  }
  Future<void> updatePassword({
    required String newPassword,
    required String oldPassword,
  }) async {
    await _appwriteService.account.updatePassword(
      password: newPassword,
      oldPassword: oldPassword,
    );
  }
  String getProfilePictureUrl(String fileId) {
    return '${_appwriteService.client.endPoint}/storage/buckets/${AppConstants.itemsImagesBucketId}/files/$fileId/view?project=${_appwriteService.client.config['project']}';
  }
  Future<appwrite_models.Document> updateUserProfileDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    return _appwriteService.databases.updateDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.usersCollectionId,
      documentId: userId,
      data: data,
    );
  }
  Future<appwrite_models.User> signupUserAccountOnly({
    required String email,
    required String password,
    required String name,
  }) async {
    const String methodName = 'signupUserAccountOnly';
    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Attempting to create Appwrite auth user: $email",
      );
      final user = await _appwriteService.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Appwrite auth user created successfully: ${user.$id}.",
      );
      return user;
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException creating user account: ${e.message} (Code: ${e.code}, Type: ${e.type})",
        s,
      );
      if (e.type == 'user_already_exists' || e.code == 409) {
        throw "An account with this email already exists. Please login or use a different email.";
      }
      throw e.message ??
          "Could not create your account at this time. (Ref: SU_CREATE_FAIL)";
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception creating user account: $e",
        s,
      );
      throw "An unexpected error occurred creating your account. (Ref: SU_CREATE_UNK)";
    }
  }
  Future<void> sendVerificationEmailForCurrentSession() async {
    const String methodName = 'sendVerificationEmailForCurrentSession';
    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Attempting to send verification email for current session.",
      );
      await _appwriteService.account.createVerification(
        url: _appVerificationWebUrl,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Verification email initiated for current session.",
      );
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException sending verification email: ${e.message} (Code: ${e.code}, Type: ${e.type})",
        s,
      );
      throw "We created your account, but couldn't send the verification email. Please try resending from the verification page or contact support. (Ref: SV_SEND_FAIL)";
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception sending verification: $e",
        s,
      );
      throw "An unexpected error occurred sending the verification email. (Ref: SV_SEND_UNK)";
    }
  }
  Future<appwrite_models.Session> loginUser({
    required String email,
    required String password,
  }) async {
    const String methodName = 'loginUser';
    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Attempting to create session for: $email",
      );
      final session = await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Session created for: $email, Session ID: ${session.$id}",
      );
      return session;
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException during login (createEmailPasswordSession): ${e.message} (Code: ${e.code}, Type: ${e.type})",
        s,
      );
      if (e.type == 'user_invalid_credentials' ||
          (e.code == 401 &&
              (e.message?.toLowerCase().contains('invalid credentials') ??
                  false))) {
        throw "Invalid email or password.";
      } else if (e.type == 'user_not_found' ||
          e.code == 404 ||
          (e.code == 401 &&
              (e.message?.toLowerCase().contains('user not found') ?? false))) {
        throw "No account found with this email.";
      }
      throw e.message ??
          "Login failed. Please try again. (Ref: LI_SESS_FAIL_P2)";
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception during login (createEmailPasswordSession): $e",
        s,
      );
      throw "An unexpected error occurred during login. (Ref: LI_SESS_UNK_P2)";
    }
  }
  Future<void> logoutUser() async {
    const String methodName = 'logoutUser';
    try {
      await _appwriteService.account.deleteSession(sessionId: 'current');
      LoggerService.logInfo(
        className,
        methodName,
        "User logged out successfully.",
      );
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException during logout: ${e.message}",
        s,
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception during logout: $e",
        s,
      );
    }
  }
  Future<appwrite_models.User> getCurrentUser() async {
    const String methodName = 'getCurrentUser';
    try {
      return await _appwriteService.account.get();
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException fetching current user: ${e.message} (Code: ${e.code}, Type: ${e.type})",
        s,
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception fetching current user: $e",
        s,
      );
      rethrow;
    }
  }
  Future<void> requestNewVerificationEmailForCurrentSession() async {
    const String methodName = 'requestNewVerificationEmailForCurrentSession';
    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Attempting to resend verification email for current session user.",
      );
      await _appwriteService.account.createVerification(
        url: _appVerificationWebUrl,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Verification email resend initiated.",
      );
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException resending verification: ${e.message} (Code: ${e.code}, Type: ${e.type})",
        s,
      );
      throw e.message ?? "Could not resend verification email.";
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Unknown exception resending verification: $e",
        s,
      );
      throw "An unexpected error occurred resending email.";
    }
  }
  Future<void> createPasswordRecovery(String email) async {
    const String methodName = 'createPasswordRecovery';
    try {
      await _appwriteService.account.createRecovery(
        email: email,
        url: _appPasswordResetWebUrl,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Password recovery email requested for $email. Appwrite returned direct success.",
      );
    } on AppwriteException catch (e) {
      if (e.type == 'user_not_found' ||
          (e.message != null &&
              e.message!.contains('password reset link has been sent'))) {
        LoggerService.logInfo(
          className,
          methodName,
          "Caught Appwrite's standard confirmation/not_found response (Type: ${e.type}), treating as success.",
        );
        return;
      } else {
        LoggerService.logError(
          className,
          methodName,
          "A real AppwriteException occurred. Type: ${e.type}, Message: ${e.message}",
        );
        rethrow;
      }
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "An unknown error occurred: $e",
      );
      rethrow;
    }
  }
  Future<appwrite_models.Target?> createPushTarget(String token) async {
    try {
      const String fcmProviderId = '684a537700161b89cc8c';
      final target = await _appwriteService.account.createPushTarget(
        targetId: ID.unique(),
        identifier: token,
        providerId: fcmProviderId,
      );
      return target;
    } on AppwriteException catch (e) {
      if (e.code != 409) rethrow;
      return null;
    }
  }
  Future<void> deletePushTarget({required String targetId}) async {
    const String methodName = 'deletePushTarget';
    try {
      await _appwriteService.account.deletePushTarget(targetId: targetId);
      LoggerService.logInfo(
        className,
        methodName,
        'Push target $targetId deleted successfully.',
      );
    } on AppwriteException catch (e) {
      if (e.code != 404) {
        LoggerService.logError(
          className,
          methodName,
          'AppwriteException deleting push target: ${e.message}',
        );
        rethrow;
      }
    }
  }
  Future<void> deleteUserAccount({
    required String userId,
    required String password,
  }) async {
    const String methodName = 'deleteUserAccount';
    try {
      final result = await _appwriteService.functions.createExecution(
        functionId: AppConstants.deleteUserAccountFunctionId,
        body: jsonEncode({'userId': userId, 'password': password}),
        method: ExecutionMethod.pOST,
      );
      final responseBody = jsonDecode(result.responseBody);
      if (responseBody['success'] == true) {
        LoggerService.logInfo(
          className,
          methodName,
          "Function execution reported success.",
        );
        return;
      } else {
        final errorMessage =
            responseBody['message'] ?? 'An unknown error occurred.';
        LoggerService.logError(
          className,
          methodName,
          "Function execution reported failure: $errorMessage",
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "A critical error occurred during function execution: $e",
      );
      throw Exception(
        'Could not connect to the server. Please try again later.',
      );
    }
  }
  Future<void> deleteUnverifiedUserAccount({required String userId}) async {
    const String methodName = 'deleteUnverifiedUserAccount';
    try {

      LoggerService.logInfo(
        className,
        methodName,
        "Creating JWT for function execution...",
      );
      final jwtResponse = await _appwriteService.account.createJWT();
      final String userJwt = jwtResponse.jwt;
      LoggerService.logInfo(className, methodName, "Successfully created JWT.");

      LoggerService.logInfo(
        className,
        methodName,
        "Executing function with user ID and JWT...",
      );
      final result = await _appwriteService.functions.createExecution(
        functionId: AppConstants.deleteUnverifiedUserFunctionId,
        body: jsonEncode({
          'userIdToDelete': userId,
          'jwt': userJwt,
        }),
        method: ExecutionMethod.pOST,
      );

      if (result.status == 'failed') {
        LoggerService.logError(
          className,
          methodName,
          "Function execution process failed. Errors: ${result.errors}",
        );
        throw Exception('The server-side function failed to execute.');
      }

      if (result.responseStatusCode >= 200 && result.responseStatusCode < 300) {
        final responseBody = jsonDecode(result.responseBody);
        if (responseBody['success'] == true) {
          LoggerService.logInfo(
            className,
            methodName,
            "Function successfully deleted user $userId.",
          );
          return;
        } else {
          final errorMessage =
              responseBody['message'] ?? 'Backend failed to delete account.';
          throw Exception(errorMessage);
        }
      } else {
        throw Exception(
          'Server function returned status code ${result.responseStatusCode}',
        );
      }
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "A critical error occurred during function execution: $e",
      );
      throw Exception(
        'Could not complete the request. Please try again later.',
      );
    }
  }
  Future<Map<String, dynamic>> fetchPublicUserProfile(
    String targetUserId,
  ) async {
    const String methodName = 'fetchPublicUserProfile';
    try {
      final result = await _appwriteService.functions.createExecution(
        functionId: AppConstants.getUserProfileFunctionId,
        body: jsonEncode({'targetUserId': targetUserId}),
        method: ExecutionMethod.pOST,
      );
      final responseBody = jsonDecode(result.responseBody);
      if (responseBody['success'] == true) {
        LoggerService.logInfo(
          className,
          methodName,
          "Function execution reported success for user $targetUserId.",
        );
        return responseBody['data'] as Map<String, dynamic>;
      } else {
        final errorMessage =
            responseBody['message'] ?? 'An unknown error occurred.';
        throw Exception(errorMessage);
      }
    } on AppwriteException catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "AppwriteException fetching profile for $targetUserId: ${e.message}",
      );
      throw Exception(e.message ?? 'Failed to fetch user profile.');
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "A critical error occurred during function execution: $e",
      );
      throw Exception(
        'Could not connect to the server. Please try again later.',
      );
    }
  }
  Future<void> triggerUpdateUserAvatarInConversations(
    String userId,
    String? newAvatarUrl,
  ) async {
    try {
      await _appwriteService.functions.createExecution(
        functionId: AppConstants.updateConversationsFunctionId,
        body: jsonEncode({
          'type': 'avatarUpdate',
          'userId': userId,
          'newAvatarUrl': newAvatarUrl,
        }),
      );
    } on AppwriteException catch (e) {

      LoggerService.logError(
        "AuthProvider",
        "triggerUpdateUserAvatarInConversations",
        'AppwriteException while triggering updateUserAvatarInConversations $e',
      );
    }
  }
  Future<void> updateUserAttributes(
    String userId,
    Map<String, dynamic> data,
  ) async {
    const String methodName = 'updateUserAttributes';
    try {
      await _appwriteService.databases.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: userId,
        data: data,
      );
      LoggerService.logInfo(
        className,
        methodName,
        "User attributes updated for $userId",
      );
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to update user attributes: $e",
      );
      rethrow;
    }
  }
}
