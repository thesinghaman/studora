import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:studora/app/data/models/user_profile_model.dart';
import 'package:studora/app/modules/blocked_users/controllers/blocked_users_controller.dart';
class BlockedUserDetailView extends StatelessWidget {
  final UserProfileModel user;
  const BlockedUserDetailView({super.key, required this.user});
  @override
  Widget build(BuildContext context) {
    final BlockedUsersController controller =
        Get.find<BlockedUsersController>();
    final theme = Theme.of(context);
    final bool hasFullDetails = user.email != "private";
    return Scaffold(
      appBar: AppBar(title: Text(user.userName)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  user.userAvatarUrl != null && user.userAvatarUrl!.isNotEmpty
                  ? NetworkImage(user.userAvatarUrl!)
                  : null,
              child: user.userAvatarUrl == null || user.userAvatarUrl!.isEmpty
                  ? Text(
                      user.getInitials(),
                      style: theme.textTheme.headlineLarge,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.userName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (hasFullDetails)
            Center(
              child: Text(
                user.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 12.0),
          const Divider(height: 24.0),
          if (hasFullDetails && user.dateJoined != null) ...[
            const SizedBox(height: 30),
            _buildProfileDetailRow(
              context,
              CupertinoIcons.barcode,
              "Roll Number",
              user.rollNumber,
            ),
            _buildProfileDetailRow(
              context,
              CupertinoIcons.house_fill,
              "Hostel / Residence",
              user.hostel,
            ),
            _buildProfileDetailRow(
              context,
              CupertinoIcons.calendar_badge_plus,
              "Joined On",
              DateFormat('MMM d, yyyy').format(user.dateJoined!),
            ),
          ] else ...[
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Further details are hidden as this user may have also blocked you.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 40),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(CupertinoIcons.hand_raised_slash),
              label: const Text("Unblock User"),
              onPressed: () => controller.unblockUser(user.userId),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  Widget _buildProfileDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
  ) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
