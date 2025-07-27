import 'dart:io';
import 'package:appwrite/appwrite.dart' as appwrite_sdk;
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/user_model.dart' as studora_user;
import 'package:studora/app/data/models/user_profile_model.dart';
import 'package:studora/app/data/providers/auth_provider.dart';
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/services/notification_service.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/services/logger_service.dart';
class AuthRepository {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final DatabaseProvider _databaseProvider = Get.find<DatabaseProvider>();
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final StorageService _storageService = Get.find<StorageService>();
  static const String className = 'AuthRepository';
  final Rx<studora_user.UserModel?> appUser = Rx<studora_user.UserModel?>(null);
  Future<appwrite_models.User?> getCurrentAppwriteUser() async {
    return _authProvider.getCurrentUser();
  }
  String get currencySymbol => appUser.value?.currencySymbol ?? '₹';
  Future<appwrite_models.Target?> _registerDeviceToken() async {
    const String methodName = '_registerDeviceToken';
    try {
      final String? fcmToken = await _notificationService.getFcmToken();
      if (fcmToken != null) {
        return await _authProvider.createPushTarget(fcmToken);
      }
      return null;
    } on appwrite_sdk.AppwriteException catch (e) {
      if (e.code == 409) {
        LoggerService.logWarning(
          className,
          methodName,
          'Push target already exists, which is OK.',
        );
        return null;
      }
      LoggerService.logError(
        className,
        methodName,
        'Failed to register device token: $e',
        e,
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        'Generic failure in register device token: $e',
        s,
      );
      return null;
    }
  }
  Future<void> enablePushNotifications() async {
    await _registerDeviceToken();
    LoggerService.logInfo(
      className,
      'enablePushNotifications',
      'Push notification registration check completed.',
    );
  }
  Future<void> disablePushNotifications() async {
    final String? targetId = _storageService.read('push_target_id');
    if (targetId != null) {
      await _authProvider.deletePushTarget(targetId: targetId);
      await _storageService.remove('push_target_id');
      LoggerService.logInfo(
        className,
        'disablePushNotifications',
        'Push notifications disabled for target ID: $targetId',
      );
    }
  }
  Future<studora_user.UserModel> signupCreateProfileLoginAndVerify({
    required String name,
    required String email,
    required String password,
    required String collegeId,
    required String currencySymbol,
    String? rollNumber,
    String? hostel,
  }) async {
    const String methodName = 'signupCreateProfileLoginAndVerify';
    appwrite_models.User? appwriteAuthUser;
    try {
      appwriteAuthUser = await _authProvider.signupUserAccountOnly(
        email: email,
        password: password,
        name: name,
      );
      await _authProvider.loginUser(email: email, password: password);
      LoggerService.logInfo(
        className,
        methodName,
        "User ${appwriteAuthUser.$id} logged in immediately after creation.",
      );
      await _authProvider.sendVerificationEmailForCurrentSession();
      LoggerService.logInfo(
        className,
        methodName,
        "Verification email initiated for logged-in user ${appwriteAuthUser.$id}.",
      );
      final userProfileData = studora_user.UserModel(
        userId: appwriteAuthUser.$id,
        userName: name,
        email: email,
        collegeId: collegeId,
        rollNumber: rollNumber,
        hostel: hostel,
        dateJoined: DateTime.parse(appwriteAuthUser.registration),
        currencySymbol: currencySymbol,
        userAvatarFileId: null,
        userAvatarUrl: null,
        wishlist: [],
        blockedUsers: [],
        reportedContent: [],
      );
      LoggerService.logInfo(
        className,
        methodName,
        "Creating user profile in DB for ${appwriteAuthUser.$id}",
      );
      await _databaseProvider.createDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: appwriteAuthUser.$id,
        data: userProfileData.toJson(),
        permissions: [
          appwrite_sdk.Permission.read(
            appwrite_sdk.Role.user(appwriteAuthUser.$id),
          ),
          appwrite_sdk.Permission.update(
            appwrite_sdk.Role.user(appwriteAuthUser.$id),
          ),
        ],
      );
      LoggerService.logInfo(
        className,
        methodName,
        "User profile created for ${appwriteAuthUser.$id}",
      );
      appUser.value = userProfileData;
      await updateUserStatus(true);
      await enablePushNotifications();
      return userProfileData;
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Full signup flow failed: $e",
        s,
      );
      rethrow;
    }
  }
  Future<studora_user.UserModel> loginAndFetchVerifiedProfile({
    required String email,
    required String password,
  }) async {
    const String methodName = 'loginAndFetchVerifiedProfile';
    try {
      await _authProvider.loginUser(email: email, password: password);
      final appwriteAuthUser = await _authProvider.getCurrentUser();
      if (!appwriteAuthUser.emailVerification) {
        LoggerService.logWarning(
          className,
          methodName,
          "Login attempt for unverified email: $email. Session created but user cannot proceed.",
        );
        throw "Your email address is not verified. Please check your email (and spam folder) for the verification link.";
      }
      LoggerService.logInfo(
        className,
        methodName,
        "Email verified for ${appwriteAuthUser.$id}. Fetching DB profile.",
      );
      final userProfileDoc = await _databaseProvider.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: appwriteAuthUser.$id,
      );
      if (userProfileDoc != null) {
        LoggerService.logInfo(
          className,
          methodName,
          "User profile found for ${appwriteAuthUser.$id}",
        );
        final userModel = studora_user.UserModel.fromJson(
          userProfileDoc.data,
          userProfileDoc.$id,
        );
        appUser.value = userModel;
        await updateUserStatus(true);
        await enablePushNotifications();
        return userModel;
      } else {
        LoggerService.logError(
          className,
          methodName,
          "CRITICAL: Verified user ${appwriteAuthUser.$id} has no profile in DB. Logging out.",
        );
        await _authProvider.logoutUser();
        appUser.value = null;
        throw "Your user profile could not be loaded. Please contact support. (Ref: LPROF_NF_VERIFIED2)";
      }
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Login and fetch profile process failed: $e",
        s,
      );
      rethrow;
    }
  }
  Future<studora_user.UserModel?> getCurrentAppUser({
    bool forceRemote = false,
  }) async {
    const String methodName = 'getCurrentAppUser';
    if (appUser.value != null && !forceRemote) {
      LoggerService.logInfo(
        className,
        methodName,
        "Returning cached app user: ${appUser.value!.userId}",
      );
      return appUser.value;
    }
    try {
      final appwriteUser = await _authProvider.getCurrentUser();
      final userProfileDoc = await _databaseProvider.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: appwriteUser.$id,
      );
      if (userProfileDoc != null) {
        final userModel = studora_user.UserModel.fromJson(
          userProfileDoc.data,
          userProfileDoc.$id,
        );
        appUser.value = userModel;
        LoggerService.logInfo(
          className,
          methodName,
          "Fetched and cached app user: ${appUser.value!.userId}",
        );
        await updateUserStatus(true);
        await enablePushNotifications();
        return appUser.value;
      } else {
        LoggerService.logWarning(
          className,
          methodName,
          "Appwrite session exists but no DB profile for ${appwriteUser.$id}. Logging out.",
        );
        await _authProvider.logoutUser();
        appUser.value = null;
        return null;
      }
    } on appwrite_sdk.AppwriteException {
      LoggerService.logInfo(
        className,
        methodName,
        "No active Appwrite session found.",
      );
      appUser.value = null;
      return null;
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Generic error checking for current user: $e",
        s,
      );
      appUser.value = null;
      return null;
    }
  }
  Future<void> updateUserWishlist(List<String> newWishlist) async {
    const String methodName = 'updateUserWishlist';
    if (appUser.value == null) {
      LoggerService.logError(
        className,
        methodName,
        "No logged-in user found to update wishlist.",
      );
      throw "User not authenticated. Cannot update wishlist.";
    }
    final String currentUserId = appUser.value!.userId;
    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Updating wishlist for user $currentUserId with ${newWishlist.length} items.",
      );
      await _databaseProvider.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: currentUserId,
        data: {'wishlist': newWishlist},
      );
      appUser.value = appUser.value!.copyWith(wishlist: newWishlist);
      LoggerService.logInfo(
        className,
        methodName,
        "Wishlist updated successfully in DB and cache for user $currentUserId.",
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to update wishlist for user $currentUserId: $e",
        s,
      );
      rethrow;
    }
  }
  Future<bool> checkCurrentUserVerificationStatus() async {
    const String methodName = 'checkCurrentUserVerificationStatus';
    try {
      final appwriteUser = await _authProvider.getCurrentUser();
      return appwriteUser.emailVerification;
    } catch (e) {
      LoggerService.logInfo(
        className,
        methodName,
        "Error during verification poll (likely no active session): $e",
      );
      return false;
    }
  }
  Future<studora_user.UserModel> updateUserProfile({
    required studora_user.UserModel updatedUser,
    XFile? newAvatarFile,
    bool avatarWasRemoved = false,
  }) async {
    studora_user.UserModel userToProcess = updatedUser;
    String? finalAvatarUrl = userToProcess.userAvatarUrl;
    String? finalAvatarFileId = userToProcess.userAvatarFileId;
    if (avatarWasRemoved && userToProcess.userAvatarFileId != null) {
      await _authProvider.deleteProfilePicture(userToProcess.userAvatarFileId!);
      finalAvatarUrl = null;
      finalAvatarFileId = null;
    }
    if (newAvatarFile != null) {
      if (userToProcess.userAvatarFileId != null) {
        await _authProvider.deleteProfilePicture(
          userToProcess.userAvatarFileId!,
        );
      }
      final uploadedFile = await _authProvider.uploadProfilePicture(
        userToProcess.userId,
        File(newAvatarFile.path),
      );
      finalAvatarFileId = uploadedFile.$id;
      finalAvatarUrl = _authProvider.getProfilePictureUrl(finalAvatarFileId);
    }
    final studora_user.UserModel finalUserModel = studora_user.UserModel(
      userId: userToProcess.userId,
      userName: userToProcess.userName,
      email: userToProcess.email,
      collegeId: userToProcess.collegeId,
      rollNumber: userToProcess.rollNumber,
      hostel: userToProcess.hostel,
      dateJoined: userToProcess.dateJoined,
      fcmToken: userToProcess.fcmToken,
      wishlist: userToProcess.wishlist,
      blockedUsers: userToProcess.blockedUsers,
      reportedContent: userToProcess.reportedContent,
      userAvatarUrl: finalAvatarUrl,
      userAvatarFileId: finalAvatarFileId,
    );
    await _authProvider.updateUserProfileDocument(
      finalUserModel.userId,
      finalUserModel.toJsonForUpdate(),
    );
    appUser.value = finalUserModel;
    if (newAvatarFile != null || avatarWasRemoved) {
      await _authProvider.triggerUpdateUserAvatarInConversations(
        finalUserModel.userId,
        finalUserModel.userAvatarUrl,
      );
    }
    return finalUserModel;
  }
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authProvider.updatePassword(
      newPassword: newPassword,
      oldPassword: currentPassword,
    );
  }
  Future<void> resendVerificationEmailForCurrentSession() async {
    await _authProvider.sendVerificationEmailForCurrentSession();
  }
  Future<void> requestPasswordReset(String email) async {
    await _authProvider.createPasswordRecovery(email);
  }
  Future<void> logout() async {
    const String methodName = 'logout';
    try {
      await updateUserStatus(false);
    } catch (e) {
      LoggerService.logInfo(
        className,
        methodName,
        "Could not update user status, probably because user doc is gone. This is OK.",
      );
    }
    try {
      await _authProvider.logoutUser();
    } catch (e) {
      LoggerService.logInfo(
        className,
        methodName,
        "Could not log out server session, probably already invalid. This is OK.",
      );
    }
    appUser.value = null;
    LoggerService.logInfo(
      className,
      methodName,
      "User logged out, local cache cleared.",
    );
    Get.offAllNamed(AppRoutes.LOGIN);
  }
  Future<void> updateUserStatus(bool isOnline) async {
    const String methodName = 'updateUserStatus';
    if (appUser.value == null) return;
    final String currentUserId = appUser.value!.userId;
    final Map<String, dynamic> data = {
      'isOnline': isOnline,
      'lastSeen': isOnline ? null : DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await _databaseProvider.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: currentUserId,
        data: data,
      );
      appUser.value = appUser.value!.copyWith(
        isOnline: isOnline,
        lastSeen: isOnline ? null : DateTime.now(),
      );
      LoggerService.logInfo(
        className,
        methodName,
        "User status updated to: ${isOnline ? 'Online' : 'Offline'}",
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to update user status: $e",
        s,
      );
    }
  }
  Future<studora_user.UserModel?> getUserById(String userId) async {
    try {
      final doc = await _databaseProvider.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: userId,
      );
      if (doc != null) {
        return studora_user.UserModel.fromJson(doc.data, doc.$id);
      }
      return null;
    } catch (e) {
      LoggerService.logError('AuthRepository', 'getUserById', e);
      rethrow;
    }
  }
  Future<void> deleteUserAccount(String password) async {
    const String methodName = 'deleteUserAccount';
    if (appUser.value == null) {
      throw "User not authenticated. Cannot delete account.";
    }
    final String userId = appUser.value!.userId;
    try {
      await _authProvider.deleteUserAccount(userId: userId, password: password);
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "Exception caught in repository, re-throwing for UI: $e",
      );
      rethrow;
    }
  }

  Future<void> deleteUnverifiedCurrentUserAndLogout() async {
    const String methodName = 'deleteUnverifiedCurrentUserAndLogout';
    try {


      final appwrite_models.User currentUser = await _authProvider
          .getCurrentUser();
      final String userId = currentUser.$id;
      LoggerService.logInfo(
        className,
        methodName,
        "Diagnostic check passed: An active session exists for user $userId.",
      );

      LoggerService.logInfo(
        className,
        methodName,
        "Calling server function to delete user: $userId",
      );
      await _authProvider.deleteUnverifiedUserAccount(userId: userId);
      LoggerService.logInfo(
        className,
        methodName,
        "Backend deletion successful. Proceeding to logout.",
      );
      await logout();
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "The unverified user deletion process failed: $e",
        s,
      );
      rethrow;
    }
  }

  Future<void> blockUser(String userIdToBlock) async {
    const String methodName = 'blockUser';
    if (appUser.value == null) {
      throw Exception("User not authenticated.");
    }
    final String currentUserId = appUser.value!.userId;
    try {

      final List<String> updatedBlockedList = List<String>.from(
        appUser.value!.blockedUsers ?? [],
      );
      if (!updatedBlockedList.contains(userIdToBlock)) {
        updatedBlockedList.add(userIdToBlock);
      }
      await _databaseProvider.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: currentUserId,
        data: {'blockedUsers': updatedBlockedList},
      );

      appUser.value = appUser.value!.copyWith(blockedUsers: updatedBlockedList);
      LoggerService.logInfo(
        className,
        methodName,
        "User $userIdToBlock blocked.",
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to block user $userIdToBlock: $e",
        s,
      );
      rethrow;
    }
  }

  Future<void> unblockUser(String userIdToUnblock) async {
    const String methodName = 'unblockUser';
    if (appUser.value == null) {
      throw Exception("User not authenticated.");
    }
    final String currentUserId = appUser.value!.userId;
    try {
      final List<String> updatedBlockedList = List<String>.from(
        appUser.value!.blockedUsers ?? [],
      );
      updatedBlockedList.remove(userIdToUnblock);
      await _databaseProvider.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.usersCollectionId,
        documentId: currentUserId,
        data: {'blockedUsers': updatedBlockedList},
      );

      appUser.value = appUser.value!.copyWith(blockedUsers: updatedBlockedList);
      LoggerService.logInfo(
        className,
        methodName,
        "User $userIdToUnblock unblocked.",
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to unblock user $userIdToUnblock: $e",
        s,
      );
      rethrow;
    }
  }
  Future<UserProfileModel> getPublicUserProfile(String targetUserId) async {
    const String methodName = 'getPublicUserProfile';
    try {
      final profileData = await _authProvider.fetchPublicUserProfile(
        targetUserId,
      );
      return UserProfileModel.fromJson(profileData);
    } catch (e, s) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to get public profile for $targetUserId: $e",
        s,
      );
      rethrow;
    }
  }
  Future<void> updatePrivacySettings({
    bool? showLastSeen,
    bool? showReadReceipts,
  }) async {
    try {
      if (appUser.value == null) throw Exception("User not logged in.");
      final Map<String, dynamic> dataToUpdate = {};
      if (showLastSeen != null) {
        dataToUpdate['showLastSeen'] = showLastSeen;
      }
      if (showReadReceipts != null) {
        dataToUpdate['showReadReceipts'] = showReadReceipts;
      }
      if (dataToUpdate.isEmpty) return;
      await _authProvider.updateUserAttributes(
        appUser.value!.userId,
        dataToUpdate,
      );
      appUser.value = appUser.value?.copyWith(
        showLastSeen: showLastSeen ?? appUser.value?.showLastSeen,
        showReadReceipts: showReadReceipts ?? appUser.value?.showReadReceipts,
      );
    } catch (e) {
      LoggerService.logError('AuthRepository', 'updatePrivacySettings', e);
      rethrow;
    }
  }
}
