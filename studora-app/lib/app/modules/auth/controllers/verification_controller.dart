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
  final VerificationType verificationType =
      Get.arguments['verificationType'] ?? VerificationType.emailSignup;
  var isDialogLoading = false.obs;
  var screenTitle = "".obs;
  var primaryStatusMessage = "".obs;
  var detailedStatusMessage = "".obs;
  var isVerifying = true.obs;
  var isVerified = false.obs;
  var isResendButtonActive = true.obs;
  var resendCooldownTime = 0.obs;
  Timer? _cooldownTimer;
  Timer? _pollingTimer;
  @override
  void onInit() {
    super.onInit();
    if (verificationType == VerificationType.emailSignup) {
      screenTitle.value = "Check Your Email";
      primaryStatusMessage.value =
          "A verification link has been sent to $userEmail.";
      detailedStatusMessage.value =
          "Please click the link in your email to activate your account. We'll check your status automatically.";
      startPollingForVerification();
    } else if (verificationType == VerificationType.passwordChange) {
      screenTitle.value = "Action Required";
      primaryStatusMessage.value =
          "A password reset link has been sent to $userEmail.";
      detailedStatusMessage.value =
          "Please follow the instructions in the email to complete your password reset.";
      isVerifying.value = false;
    }
  }
  void startPollingForVerification() {
    const String methodName = 'startPollingForVerification';
    LoggerService.logInfo(
      className,
      methodName,
      "Starting verification polling for $userEmail",
    );
    isVerifying(true);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 7), (timer) async {
      LoggerService.logInfo(
        className,
        methodName,
        "Polling for verification status for $userEmail...",
      );
      bool verifiedStatus = await _authRepository
          .checkCurrentUserVerificationStatus();
      if (verifiedStatus) {
        LoggerService.logInfo(
          className,
          methodName,
          "Email $userEmail successfully verified via polling!",
        );
        isVerified(true);
        isVerifying(false);
        _cooldownTimer?.cancel();
        isResendButtonActive(true);
        resendCooldownTime(0);
        screenTitle.value = "Account Verified Successfully";
        primaryStatusMessage.value = "Your email address has been confirmed.";
        detailedStatusMessage.value =
            "Welcome to Studora! You're all set and ready to go.";
        timer.cancel();
        SnackbarService.showSuccess(
          title: "Verification Complete!",
          "Your account is now active.",
        );
      } else {
        LoggerService.logInfo(
          className,
          methodName,
          "Email $userEmail not yet verified.",
        );
        if (verificationType == VerificationType.emailSignup &&
            !isVerified.value) {
          primaryStatusMessage.value =
              "Still waiting for you to click the link sent to $userEmail.";
          detailedStatusMessage.value =
              "Make sure to check your spam folder. We're checking automatically.";
        }
      }
    });
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
  Future<void> resendVerificationEmail() async {
    const String methodName = 'resendVerificationEmail';
    if (!isResendButtonActive.value) return;
    if (userEmail.isEmpty) {
      SnackbarService.showError("Email address not available to resend link.");
      return;
    }
    _startResendCooldown();
    try {
      if (verificationType == VerificationType.emailSignup) {
        await _authRepository.resendVerificationEmailForCurrentSession();
        primaryStatusMessage.value =
            "A new verification link has been sent to $userEmail.";
        detailedStatusMessage.value =
            "Please check your email (and spam folder) and click the link.";
        SnackbarService.showSuccess(
          title: "Verification Email Resent",
          "A new link has been sent to $userEmail.",
        );
        if (!isVerified.value) {
          startPollingForVerification();
        }
      } else if (verificationType == VerificationType.passwordChange) {
        await _authRepository.requestPasswordReset(userEmail);
        primaryStatusMessage.value =
            "A new password reset link has been sent to $userEmail.";
        detailedStatusMessage.value =
            "Please check your email to proceed with resetting your password.";
        SnackbarService.showSuccess(
          title: "Password Reset Link Resent",
          "A new link has been sent to $userEmail.",
        );
      }
    } catch (e) {
      LoggerService.logError(className, methodName, "Error resending link: $e");
      SnackbarService.showError(e.toString());
      isResendButtonActive(true);
      resendCooldownTime(0);
      _cooldownTimer?.cancel();
    }
  }

  void handleIncorrectEmail() {
    const String methodName = 'handleIncorrectEmail';
    LoggerService.logInfo(
      className,
      methodName,
      "User reported incorrect email.",
    );
    _pollingTimer?.cancel();

    isDialogLoading.value = false;
    Get.dialog(

      Obx(
        () => PopScope(

          canPop: !isDialogLoading.value,
          child: AlertDialog(
            title: const Text("Incorrect Email Address?"),

            content: isDialogLoading.value
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text("Deleting Account..."),
                    ],
                  )
                : const Text(
                    "Continuing will permanently delete your unverified account. You can then sign up again.",
                  ),

            actions: isDialogLoading.value
                ? []
                : [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        Get.back();
                        if (!isVerified.value) {
                          startPollingForVerification();
                        }
                      },
                    ),
                    TextButton(
                      child: Text(
                        "Yes, Delete Account",
                        style: TextStyle(color: Get.theme.colorScheme.error),
                      ),
                      onPressed: () async {

                        isDialogLoading.value = true;

                        final bool operationSucceeded =
                            await _triggerFullAccountDeletion();

                        if (!operationSucceeded) {

                          if (Get.isDialogOpen ?? false) {
                            Get.back(closeOverlays: true);
                          }
                          await Future.delayed(
                            const Duration(milliseconds: 300),
                          );

                          SnackbarService.showError(
                            "Could not delete your account. Please try again or contact support.",
                          );
                        }
                      },
                    ),
                  ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> _triggerFullAccountDeletion() async {
    const String methodName = '_triggerFullAccountDeletion';
    try {

      await _authRepository.deleteUnverifiedCurrentUserAndLogout();

      return true;
    } catch (e) {
      LoggerService.logError(
        className,
        methodName,
        "Failed to delete account: $e",
      );

      return false;
    }
  }
  void proceedToLogin() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
  void proceedToApp() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
  }
  @override
  void onClose() {
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.onClose();
  }
}
