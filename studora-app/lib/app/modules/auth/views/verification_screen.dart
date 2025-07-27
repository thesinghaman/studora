import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/verification_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
class VerificationScreen extends GetView<VerificationController> {
  const VerificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isVerified.value
                ? "Account Verified!"
                : (controller.verificationType == VerificationType.emailSignup
                      ? "Check Your Email"
                      : "Action Required"),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
              vertical: screenHeight * 0.02,
            ),
            child: Obx(() {
              IconData headerIconData;
              String headerTextDisplay;
              String mainButtonText;
              VoidCallback mainButtonAction;
              bool showResendButtonVisibilityFlag;
              if (controller.isVerified.value) {
                headerIconData = Icons.check_circle_outline_rounded;
                headerTextDisplay = "Success!";
              } else if (controller.verificationType ==
                  VerificationType.emailSignup) {
                headerIconData = Icons.mark_email_read_outlined;
                headerTextDisplay = "Check Your Email";
              } else {
                headerIconData = Icons.phonelink_lock_outlined;
                headerTextDisplay = "Action Required";
              }
              if (controller.isVerified.value) {
                mainButtonText = "Get Started";
                mainButtonAction = controller.proceedToApp;
                showResendButtonVisibilityFlag = false;
              } else {
                mainButtonText =
                    (controller.verificationType ==
                        VerificationType.emailSignup)
                    ? "Go to Login (Check Email First)"
                    : "Go to Login";
                mainButtonAction = controller.proceedToLogin;
                showResendButtonVisibilityFlag = true;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(height: screenHeight * 0.05),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: Icon(
                      headerIconData,
                      size: screenHeight * 0.12,
                      color: controller.isVerified.value
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      headerTextDisplay,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      controller.primaryStatusMessage.value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!controller.isVerified.value &&
                      controller.verificationType ==
                          VerificationType.emailSignup) ...[
                    SizedBox(height: screenHeight * 0.01),
                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 450),
                      child: Text(
                        controller.userEmail,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.025),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      controller.detailedStatusMessage.value,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (controller.isVerifying.value &&
                      !controller.isVerified.value)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(radius: 10),
                          const SizedBox(width: 10),
                          Text(
                            "Checking status...",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.05),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: mainButtonAction,
                      child: Text(mainButtonText),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  if (showResendButtonVisibilityFlag)
                    Obx(() {
                      final bool isActive =
                          controller.isResendButtonActive.value;
                      final int cooldown = controller.resendCooldownTime.value;
                      String buttonText =
                          controller.verificationType ==
                              VerificationType.emailSignup
                          ? "Didn't receive the email? Resend"
                          : "Didn't get the link? Resend Link";
                      if (!isActive && cooldown > 0) {
                        buttonText = "Resend in ${cooldown}s";
                      }
                      return AnimatedFadeSlide(
                        delay: const Duration(milliseconds: 700),
                        child: TextButton(
                          onPressed: isActive
                              ? controller.resendVerificationEmail
                              : null,
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              color: isActive
                                  ? theme.colorScheme.secondary
                                  : theme.disabledColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  if (!controller.isVerified.value &&
                      controller.verificationType ==
                          VerificationType.emailSignup) ...[
                    AnimatedFadeSlide(
                      delay: const Duration(milliseconds: 800),
                      child: TextButton(
                        onPressed: controller.handleIncorrectEmail,
                        child: Text(
                          "Entered the wrong email?",
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: screenHeight * 0.05),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
