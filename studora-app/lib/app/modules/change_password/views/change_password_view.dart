import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/change_password/controllers/change_password_controller.dart';
import 'package:studora/app/shared_components/utils/input_validators.dart';
class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.canSaveChanges.value && !controller.isLoading.value
                  ? controller.submitChangePassword
                  : null,
              child: controller.isLoading.value
                  ? const CupertinoActivityIndicator()
                  : Text(
                      "Save",
                      style: TextStyle(
                        color: controller.canSaveChanges.value
                            ? theme.colorScheme.primary
                            : theme.disabledColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              Text(
                "Your new password must be different from any passwords you've used previously.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32.0),
              Obx(
                () => _buildPasswordField(
                  label: "Current Password",
                  controller: controller.currentPasswordController,
                  isObscured: controller.isCurrentPasswordObscured.value,
                  onToggleObscure: () =>
                      controller.isCurrentPasswordObscured.toggle(),
                  theme: theme,
                  validator: InputValidators.validatePassword,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => _buildPasswordField(
                  label: "New Password",
                  controller: controller.newPasswordController,
                  isObscured: controller.isNewPasswordObscured.value,
                  onToggleObscure: () =>
                      controller.isNewPasswordObscured.toggle(),
                  theme: theme,
                  validator: InputValidators.validatePassword,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => _buildPasswordField(
                  label: "Confirm New Password",
                  controller: controller.confirmPasswordController,
                  isObscured: controller.isConfirmPasswordObscured.value,
                  onToggleObscure: () =>
                      controller.isConfirmPasswordObscured.toggle(),
                  theme: theme,
                  validator: (value) => InputValidators.validateConfirmPassword(
                    value,
                    controller.newPasswordController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleObscure,
    required ThemeData theme,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            hintText: "Enter $label",
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
