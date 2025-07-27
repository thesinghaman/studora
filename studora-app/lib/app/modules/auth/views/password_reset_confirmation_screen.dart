import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
class PasswordResetConfirmationScreen extends StatelessWidget {
  const PasswordResetConfirmationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String email = Get.arguments as String? ?? 'your email address';
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AnimatedFadeSlide(
              duration: Duration(milliseconds: 400),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 80,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedFadeSlide(
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Check Your Inbox!',
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
                "We've sent a password reset link to:\n$email",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const AnimatedFadeSlide(
              duration: Duration(milliseconds: 700),
              child: Text(
                "If you don't see it, please check your spam folder.",
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
            AnimatedFadeSlide(
              duration: const Duration(milliseconds: 800),
              child: FilledButton.icon(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.until(
                  (route) => route.settings.name == AppRoutes.LOGIN,
                ),
                label: const Text('Back to Login'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
