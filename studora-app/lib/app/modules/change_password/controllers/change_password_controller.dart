import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
class ChangePasswordController extends GetxController {
  static const String _className = 'ChangePasswordController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  var isLoading = false.obs;
  var canSaveChanges = false.obs;
  var isCurrentPasswordObscured = true.obs;
  var isNewPasswordObscured = true.obs;
  var isConfirmPasswordObscured = true.obs;

  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;
  @override
  void onInit() {
    super.onInit();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    currentPasswordController.addListener(updateCanSaveChanges);
    newPasswordController.addListener(updateCanSaveChanges);
    confirmPasswordController.addListener(updateCanSaveChanges);
  }
  void updateCanSaveChanges() {
    canSaveChanges.value =
        currentPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty;
  }
  Future<void> submitChangePassword() async {
    if (!formKey.currentState!.validate()) {
      SnackbarService.showWarning(
        "Please correct the errors before submitting.",
      );
      return;
    }
    isLoading.value = true;
    try {
      await _authRepository.updatePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );
      Get.back();
      SnackbarService.showSuccess("Password changed successfully!");
    } catch (e) {
      LoggerService.logError(
        _className,
        'submitChangePassword',
        'Failed to change password: $e',
      );
      SnackbarService.showError(
        "Failed to change password. Please check your current password and try again.",
      );
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
