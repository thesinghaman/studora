import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/services/logger_service.dart';

class VerificationController extends GetxController {
  static const String className = 'VerificationController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final String userEmail = Get.arguments['email'] ?? 'your-email@example.com';
  final String userId = Get.arguments['userId'] ?? '';
  final VerificationType verificationType =
      Get.arguments['verificationType'] ?? VerificationType.emailSignup;

  final TextEditingController otpController = TextEditingController();
  var isVerifying = false.obs;
  var isVerified = false.obs;
  var isResendButtonActive = true.obs;
  var resendCooldownTime = 0.obs;
  Timer? _cooldownTimer;

  @override
  void onInit() {
    super.onInit();
    LoggerService.logInfo(
      className,
      'onInit',
      'OTP Verification screen initialized for email: $userEmail, userId: $userId',
    );
  }

  Future<void> verifyOtp() async {
    const String methodName = 'verifyOtp';

    final otpCode = otpController.text.trim();

    if (otpCode.isEmpty) {
      SnackbarService.showWarning(
        title: "Missing Code",
        "Please enter the verification code.",
      );
      return;
    }

    if (otpCode.length != 6) {
      SnackbarService.showWarning(
        title: "Invalid Code",
        "Please enter a 6-digit code.",
      );
      return;
    }

    if (userId.isEmpty) {
      SnackbarService.showError(
        "User ID not found. Please try signing up again.",
      );
      return;
    }

    isVerifying(true);

    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Verifying OTP for user: $userId",
      );

      // Verify OTP and create session
      await _authRepository.verifyOtpAndCreateSession(
        userId: userId,
        otpCode: otpCode,
      );

      LoggerService.logInfo(
        className,
        methodName,
        "OTP verified successfully. Marking email as verified.",
      );

      // Mark email as verified in database
      await _authRepository.markEmailAsVerified(userId);

      LoggerService.logInfo(
        className,
        methodName,
        "Email marked as verified. User can now proceed to app.",
      );

      isVerified(true);

      SnackbarService.showSuccess(
        title: "Verification Complete!",
        "Your email has been verified successfully.",
      );

      // Navigate to app after a short delay
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "OTP verification failed: $e",
      );
      SnackbarService.showError(e.toString());
    } finally {
      isVerifying(false);
    }
  }

  void _startResendCooldown() {
    isResendButtonActive(false);
    resendCooldownTime(30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldownTime.value > 0) {
        resendCooldownTime.value--;
      } else {
        isResendButtonActive(true);
        timer.cancel();
      }
    });
  }

  Future<void> resendOtp() async {
    const String methodName = 'resendOtp';

    if (!isResendButtonActive.value) return;

    if (userEmail.isEmpty) {
      SnackbarService.showError(
        "Unable to resend code. Email not found.",
      );
      return;
    }

    _startResendCooldown();

    try {
      LoggerService.logInfo(
        className,
        methodName,
        "Resending OTP to $userEmail",
      );

      if (userId.isEmpty) {
        SnackbarService.showError(
          "Unable to resend code. User ID not found.",
        );
        return;
      }
      await _authRepository.sendOtpEmail(userId: userId, email: userEmail);

      SnackbarService.showSuccess(
        title: "Code Sent!",
        "A new verification code has been sent to $userEmail",
      );
    } catch (e) {
      LoggerService.logError(className, methodName, "Error resending OTP: $e");
      SnackbarService.showError(e.toString());
      isResendButtonActive(true);
      resendCooldownTime(0);
      _cooldownTimer?.cancel();
    }
  }

  void proceedToLogin() {
    _cooldownTimer?.cancel();
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  @override
  void onClose() {
    otpController.dispose();
    _cooldownTimer?.cancel();
    super.onClose();
  }
}
