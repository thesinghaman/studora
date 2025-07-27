import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/auth/controllers/forgot_password_controller.dart';
import 'package:studora/app/shared_components/utils/input_validators.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedFadeSlide(
                duration: const Duration(milliseconds: 400),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              AnimatedFadeSlide(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Forgot Your Password?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedFadeSlide(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  "Enter your email address below and we'll send you a link to reset your password.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AnimatedFadeSlide(
                duration: const Duration(milliseconds: 700),
                child: TextFormField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: InputValidators.validateEmail,
                ),
              ),
              const SizedBox(height: 32),
              AnimatedFadeSlide(
                duration: const Duration(milliseconds: 700),
                child: Obx(
                  () => FilledButton.icon(
                    icon: controller.isLoading.value
                        ? Container()
                        : const Icon(Icons.send_rounded),
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.sendResetLink,
                    label: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Reset Link'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
