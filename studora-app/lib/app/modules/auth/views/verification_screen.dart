import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/verification_controller.dart';
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
        title: Text(
          "Verify Email",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.05),

                // Icon
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.email_outlined,
                    size: screenHeight * 0.12,
                    color: theme.colorScheme.primary,
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Title
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    "Check Your Email",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Subtitle
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    "We've sent a 6-digit verification code to",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.01),

                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 450),
                  child: Text(
                    controller.userEmail,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // OTP Input Field
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 500),
                  child: TextField(
                    controller: controller.otpController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: 16,
                        color: theme.hintColor.withValues(alpha: 0.3),
                      ),
                      counterText: "",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Verify Button
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 600),
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isVerifying.value
                          ? null
                          : controller.verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: controller.isVerifying.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text("Verify"),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Resend Code Button
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 700),
                  child: Obx(() {
                    final bool isActive = controller.isResendButtonActive.value;
                    final int cooldown = controller.resendCooldownTime.value;
                    String buttonText = "Didn't receive the code? Resend";
                    if (!isActive && cooldown > 0) {
                      buttonText = "Resend in ${cooldown}s";
                    }
                    return TextButton(
                      onPressed: isActive ? controller.resendOtp : null,
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.disabledColor,
                        ),
                      ),
                    );
                  }),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Go to Login Button
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 750),
                  child: TextButton(
                    onPressed: controller.proceedToLogin,
                    child: Text(
                      "Back to Login",
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
