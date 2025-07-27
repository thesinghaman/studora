import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/models/user_model.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class LoginController extends GetxController {
  static const String _className = 'LoginController';
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var isPasswordVisible = false.obs;
  var isLoading = false.obs;
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
  Future<void> loginUser() async {
    if (formKey.currentState!.validate()) {
      isLoading(true);
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      LoggerService.logInfo(
        _className,
        "loginUser",
        "Login attempt for: $email",
      );
      try {
        UserModel user = await _authRepository.loginAndFetchVerifiedProfile(
          email: email,
          password: password,
        );
        LoggerService.logInfo(
          _className,
          "loginUser",
          "Login successful and email verified for: ${user.email}. User details: Name: ${user.userName}, ID: ${user.userId}",
        );
        String displayName = user.userName;
        SnackbarService.showSuccess(
          title: "Login Successful",
          "Welcome back, $displayName!",
        );
        Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
      } catch (e, s) {
        LoggerService.logError(
          _className,
          "loginUser",
          "Login error: ${e.toString()}",
          s,
        );
        if (e.toString().toLowerCase().contains(
          "email address is not verified",
        )) {
          SnackbarService.showWarning(
            title: "Email Not Verified",
            "Please verify your email. Redirecting to verification screen.",
          );
          Get.toNamed(
            AppRoutes.VERIFICATION,
            arguments: {
              'email': email,
              'verificationType': VerificationType.emailSignup,
            },
          );
        } else {
          SnackbarService.showError(title: "Login Failed", e.toString());
        }
      } finally {
        isLoading(false);
      }
    }
  }
  void navigateToSignup() {
    Get.toNamed(AppRoutes.SIGNUP);
  }
  void navigateToForgotPassword() {
    Get.toNamed(AppRoutes.FORGOT_PASSWORD);
  }
}
