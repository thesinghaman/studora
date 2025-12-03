import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  "Forgot Password?",
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              AnimatedFadeSlide(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  controller.isEmailSent.value
                      ? "Enter the code sent to your email and your new password."
                      : "Enter your email address to receive a verification code.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.05),

              if (!controller.isEmailSent.value) 
                _buildEmailForm(context, screenHeight) 
              else 
                _buildResetForm(context, screenHeight),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context, double screenHeight) {
    return Form(
      key: controller.emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: TextFormField(
              controller: controller.emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your email";
                }
                if (!GetUtils.isEmail(value)) {
                  return "Please enter a valid email";
                }
                return null;
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 500),
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.sendResetCode,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Send Code"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(BuildContext context, double screenHeight) {
    return Form(
      key: controller.resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: TextFormField(
              controller: controller.otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Verification Code",
                prefixIcon: Icon(
                  Icons.lock_clock_outlined,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter the code";
                }
                if (value.length != 6) {
                  return "Code must be 6 digits";
                }
                return null;
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 500),
            child: TextFormField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter a password";
                }
                if (value.length < 8) {
                  return "Password must be at least 8 characters";
                }
                return null;
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 600),
            child: TextFormField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please confirm your password";
                }
                return null;
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 700),
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.resetPassword,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Reset Password"),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          AnimatedFadeSlide(
            delay: const Duration(milliseconds: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: controller.resendCooldownTime.value > 0
                      ? null
                      : controller.resendCode,
                  child: Text(
                    controller.resendCooldownTime.value > 0
                        ? "Resend in ${controller.resendCooldownTime.value}s"
                        : "Resend",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: controller.resendCooldownTime.value > 0
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

