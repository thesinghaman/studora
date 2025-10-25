import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/delete_account/controllers/delete_account_controller.dart';
class DeleteConfirmationView extends GetView<DeleteAccountController> {
  const DeleteConfirmationView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Delete Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningSection(theme),
            const SizedBox(height: 24),
            _buildDataDetailsSection(theme),
            const SizedBox(height: 32),
            _buildConfirmationInput(theme),
            const SizedBox(height: 24),
            _buildFinalDeleteButton(theme),
          ],
        ),
      ),
    );
  }
  Widget _buildWarningSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This is permanent",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Deleting your profile is an irreversible action. All your data will be permanently removed.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(
                      alpha: 0.9,
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
  Widget _buildDataDetailsSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text("What will be deleted?"),
        leading: Icon(
          CupertinoIcons.info_circle_fill,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          _buildDetailListItem(theme, "Your user profile and metadata."),
          _buildDetailListItem(theme, "All your ads and their images."),
          _buildDetailListItem(theme, "All your Lost & Found posts."),
          _buildDetailListItem(theme, "Your profile picture."),
          _buildDetailListItem(theme, "Your wishlist and other saved content."),
          _buildDetailListItem(
            theme,
            "Your chat messages will be marked as deleted. They are permanently removed only when all participants have deleted the conversation.",
          ),
        ],
      ),
    );
  }
  Widget _buildDetailListItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5.0, right: 8.0),
            child: Icon(
              Icons.check,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
  Widget _buildConfirmationInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter password to confirm",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => TextFormField(
            controller: controller.passwordController,
            obscureText: !controller.isPasswordVisible.value,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  controller.isPasswordVisible.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: controller.togglePasswordVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildFinalDeleteButton(ThemeData theme) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: controller.isProcessing.value
              ? Container()
              : const Icon(CupertinoIcons.delete_solid),
          label: controller.isProcessing.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Text("Agree & Delete My Account"),
          onPressed: controller.isProcessing.value
              ? null
              : controller.confirmAndDeleteAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
