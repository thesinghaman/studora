import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
class DeleteAccountController extends GetxController {
  static const String _className = 'DeleteAccountController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final passwordController = TextEditingController();
  var isPasswordVisible = false.obs;
  var isProcessing = false.obs;
  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  Future<void> confirmAndDeleteAccount() async {
    if (passwordController.text.isEmpty) {
      SnackbarService.showError("Please enter your password to confirm.");
      return;
    }
    isProcessing.value = true;
    try {


      await _authRepository.deleteUserAccount(passwordController.text);


      await _authRepository.logout();

      SnackbarService.showSuccess(
        title: "Account Deleted",
        "Your account has been successfully deleted.",
      );
    } catch (e) {


      LoggerService.logError(
        _className,
        'confirmAndDeleteAccount',
        "Deletion failed: $e",
      );
      SnackbarService.showError(e.toString());
    } finally {

      isProcessing.value = false;
    }
  }
}
