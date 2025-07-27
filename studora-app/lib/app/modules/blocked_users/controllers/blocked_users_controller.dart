import 'dart:async';
import 'package:get/get.dart';
import 'package:studora/app/data/models/user_profile_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/modules/blocked_users/views/blocked_user_detail_view.dart';
class BlockedUsersController extends GetxController {
  static const String _className = 'BlockedUsersController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  var isLoading = true.obs;
  var blockedUsersList = <UserProfileModel>[].obs;
  StreamSubscription? _userSubscription;
  @override
  void onInit() {
    super.onInit();
    _userSubscription = _authRepository.appUser.listen((_) {
      fetchBlockedUsers();
    });
    fetchBlockedUsers();
  }
  @override
  void onClose() {
    _userSubscription?.cancel();
    super.onClose();
  }
  Future<void> fetchBlockedUsers() async {
    isLoading.value = true;
    try {
      final blockedIds = _authRepository.appUser.value?.blockedUsers ?? [];
      if (blockedIds.isEmpty) {
        blockedUsersList.clear();
      } else {
        final userFutures = blockedIds
            .map((id) => _authRepository.getPublicUserProfile(id))
            .toList();
        final users = await Future.wait(userFutures);
        blockedUsersList.value = users;
      }
    } catch (e) {
      LoggerService.logError(_className, 'fetchBlockedUsers', e);
      SnackbarService.showError("Could not load blocked users.");
    } finally {
      isLoading.value = false;
    }
  }
  void navigateToDetail(UserProfileModel user) {
    Get.to(() => BlockedUserDetailView(user: user));
  }
  Future<void> unblockUser(String userId) async {
    try {
      await _authRepository.unblockUser(userId);
      blockedUsersList.removeWhere((user) => user.userId == userId);
      Get.back();
      SnackbarService.showSuccess("User has been unblocked.");
    } catch (e) {
      LoggerService.logError(_className, 'unblockUser', e);
      SnackbarService.showError("Failed to unblock user.");
    }
  }
}
