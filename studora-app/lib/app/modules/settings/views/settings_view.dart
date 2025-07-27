import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/user_model.dart';
import 'package:studora/app/modules/settings/controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          Obx(() {
            final user = controller.currentUser.value;
            if (user != null) {
              return _buildUserProfileDisplay(context, user, theme);
            }
            return const SizedBox.shrink();
          }),
          _buildSectionSpacer(
            isFirstSection: controller.currentUser.value == null,
          ),
          _buildSectionHeader(context, "Account", theme),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.person_outline_rounded,
            title: "Edit Profile",
            onTap: controller.navigateToEditProfile,
          ),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.privacy_tip_outlined,
            title: "Privacy",
            onTap: controller.navigateToPrivacy,
          ),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.block,
            title: "Blocked Users",
            onTap: controller.navigateToBlockedUsers,
          ),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.lock_outline_rounded,
            title: "Change Password",
            onTap: controller.navigateToChangePassword,
          ),
          _buildSectionSpacer(),
          _buildSectionHeader(context, "Preferences", theme),
          Obx(
            () => _buildToggleItem(
              context,
              theme,
              icon: controller.isDarkModeEnabled.value
                  ? Icons.nightlight_outlined
                  : Icons.wb_sunny_outlined,
              title: "Dark Mode",
              value: controller.isDarkModeEnabled.value,
              onChanged: controller.onDarkModeChanged,
            ),
          ),
          Obx(
            () => _buildToggleItem(
              context,
              theme,
              icon: controller.arePushNotificationsEnabled.value
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: "Push Notifications",
              value: controller.arePushNotificationsEnabled.value,
              onChanged: controller.onPushNotificationsChanged,
            ),
          ),
          _buildSectionSpacer(),
          _buildSectionHeader(context, "Support", theme),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.help_outline_rounded,
            title: "Help & FAQ",
            onTap: controller.navigateToHelpAndFaq,
          ),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.mail_outline_rounded,
            title: "Contact Support",
            onTap: controller.navigateToContactSupport,
          ),
          _buildSectionSpacer(),
          _buildSectionHeader(context, "Legal", theme),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.article_outlined,
            title: "Terms & Conditions",
            onTap: controller.navigateToTermsAndConditions,
          ),
          _buildSettingsItem(
            context,
            theme,
            icon: Icons.shield_outlined,
            title: "Privacy Policy",
            onTap: controller.navigateToPrivacyPolicy,
          ),
          _buildSectionSpacer(),
          _buildLogoutItem(context, theme),
          const SizedBox(height: 30.0),
          Center(
            child: Text(
              "App Version 1.0.0",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Confirm Logout",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to log out?",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Get.back();
                  controller.logout();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                tileColor: theme.colorScheme.error.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(
                  Icons.cancel_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                title: Text(
                  'Cancel',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () => Get.back(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                tileColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
    );
  }

  Widget _buildUserProfileDisplay(
    BuildContext context,
    UserModel user,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundImage:
                user.userAvatarUrl != null &&
                    user.userAvatarUrl!.startsWith('http')
                ? NetworkImage(user.userAvatarUrl!)
                : null,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.6,
            ),
            child:
                (user.userAvatarUrl == null ||
                    !user.userAvatarUrl!.startsWith('http'))
                ? Text(
                    user.getInitials(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16.0),
          Text(
            user.userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSectionSpacer({bool isFirstSection = false}) {
    return SizedBox(height: isFirstSection ? 24.0 : 16.0);
  }

  Widget _buildSettingsItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 20.0),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
            const SizedBox(width: 20.0),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => _showLogoutConfirmationDialog(context),
      highlightColor: theme.colorScheme.error.withValues(alpha: 0.05),
      splashColor: theme.colorScheme.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              Icons.exit_to_app_rounded,
              color: theme.colorScheme.error,
              size: 22,
            ),
            const SizedBox(width: 20.0),
            Expanded(
              child: Text(
                "Logout",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
