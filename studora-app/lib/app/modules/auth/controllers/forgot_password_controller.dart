import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final isLoading = false.obs;
  static const String className = 'ForgotPasswordController';
  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
  Future<void> sendResetLink() async {
    if (formKey.currentState?.validate() != true) {
      LoggerService.logWarning(
        className,
        'sendResetLink',
        'Form validation failed or form state was null.',
      );
      return;
    }
    isLoading.value = true;
    try {
      final email = emailController.text.trim();
      await _authRepository.requestPasswordReset(email);
      Get.toNamed(AppRoutes.PASSWORD_RESET_CONFIRMATION, arguments: email);
    } catch (e) {
      LoggerService.logError(className, 'sendResetLink', e.toString());
      SnackbarService.showError('Failed to send reset link: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
