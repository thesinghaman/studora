import 'package:get/get.dart';

import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class PrivacyController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  var showLastSeen = true.obs;
  var showReadReceipts = true.obs;
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final currentUser = _authRepository.appUser.value;
    if (currentUser != null) {
      showLastSeen.value = currentUser.showLastSeen;
      showReadReceipts.value = currentUser.showReadReceipts;
    }
  }

  Future<void> updateShowLastSeen(bool value) async {
    showLastSeen.value = value;
    await _updateSettings(showLastSeen: value);
  }

  Future<void> updateShowReadReceipts(bool value) async {
    showReadReceipts.value = value;
    await _updateSettings(showReadReceipts: value);
  }

  Future<void> _updateSettings({
    bool? showLastSeen,
    bool? showReadReceipts,
  }) async {
    try {
      await _authRepository.updatePrivacySettings(
        showLastSeen: showLastSeen,
        showReadReceipts: showReadReceipts,
      );
      SnackbarService.showSuccess("Privacy setting updated.");
    } catch (e) {
      LoggerService.logError('PrivacyController', '_updateSettings', e);
      SnackbarService.showError("Failed to update setting. Please try again.");

      _loadCurrentSettings();
    }
  }
}
