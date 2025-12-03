import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/services/logger_service.dart';

class ForgotPasswordController extends GetxController {
  static const String className = 'ForgotPasswordController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

  var isEmailSent = false.obs;
  var isLoading = false.obs;
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  
  // Store userId after email lookup
  String? _userId;

  // Timer for resend
  var resendCooldownTime = 0.obs;
  Timer? _cooldownTimer;

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> sendResetCode() async {
    if (!emailFormKey.currentState!.validate()) return;

    isLoading(true);
    try {
      final email = emailController.text.trim();
      
      // 1. Get User ID from Backend
      _userId = await _authRepository.initiatePasswordReset(email);
      
      // 2. Send OTP via Appwrite
      await _authRepository.sendOtpEmail(userId: _userId!, email: email);

      isEmailSent(true);
      startResendCooldown();
      SnackbarService.showSuccess(
        title: "Code Sent",
        "Please check your email for the verification code.",
      );
    } catch (e) {
      LoggerService.logError(className, 'sendResetCode', e.toString());
      SnackbarService.showError(e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> resetPassword() async {
    if (!resetFormKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      SnackbarService.showError("Passwords do not match");
      return;
    }

    isLoading(true);
    try {
      await _authRepository.completePasswordReset(
        userId: _userId!,
        secret: otpController.text.trim(),
        newPassword: passwordController.text.trim(),
      );

      SnackbarService.showSuccess(
        title: "Success",
        "Password reset successfully. Please login.",
      );
      Get.offAllNamed(AppRoutes.LOGIN);
    } catch (e) {
      LoggerService.logError(className, 'resetPassword', e.toString());
      SnackbarService.showError(e.toString());
    } finally {
      isLoading(false);
    }
  }

  void startResendCooldown() {
    resendCooldownTime.value = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldownTime.value > 0) {
        resendCooldownTime.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendCode() async {
    if (resendCooldownTime.value > 0) return;
    
    isLoading(true);
    try {
      await _authRepository.sendOtpEmail(
        userId: _userId!,
        email: emailController.text.trim(),
      );
      startResendCooldown();
      SnackbarService.showSuccess(
        title: "Code Resent",
        "A new verification code has been sent.",
      );
    } catch (e) {
      SnackbarService.showError(e.toString());
    } finally {
      isLoading(false);
    }
  }
}
