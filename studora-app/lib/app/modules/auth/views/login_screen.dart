import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/modules/auth/controllers/login_controller.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: SizedBox(
            height: screenHeight * 0.9,
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      height: screenHeight * 0.15,
                      alignment: Alignment.center,
                      child: Text(
                        "Studora",
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 350),
                    child: Text(
                      "Login to continue your campus journey.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email / Student ID",
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Theme.of(
                            context,
                          ).iconTheme.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or ID';
                        }
                        if (!value.contains('@') &&
                            !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid email or student ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: Obx(
                      () => TextFormField(
                        controller: controller.passwordController,
                        obscureText: !controller.isPasswordVisible.value,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Theme.of(
                              context,
                            ).iconTheme.color?.withValues(alpha: 0.7),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Theme.of(
                                context,
                              ).iconTheme.color?.withValues(alpha: 0.7),
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 550),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.FORGOT_PASSWORD),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.loginUser,
                        child: controller.isLoading.value
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
                            : const Text("Login"),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 700),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: controller.navigateToSignup,
                          child: Text(
                            "Sign Up",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
