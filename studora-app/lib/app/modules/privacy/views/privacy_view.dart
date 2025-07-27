import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/privacy/controllers/privacy_controller.dart';

class PrivacyView extends GetView<PrivacyController> {
  const PrivacyView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Settings")),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildToggleTile(
              context,
              icon: CupertinoIcons.time,
              title: "Show Last Seen",
              subtitle:
                  "If turned off, you won't be able to see other people's last seen.",
              value: controller.showLastSeen.value,
              onChanged: controller.updateShowLastSeen,
            ),
            const Divider(height: 24),
            _buildToggleTile(
              context,
              icon: CupertinoIcons.checkmark_seal_fill,
              title: "Show Read Receipts",
              subtitle:
                  "If turned off, you won't be able to see read receipts from others.",
              value: controller.showReadReceipts.value,
              onChanged: controller.updateShowReadReceipts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: theme.colorScheme.primary,
      ),
    );
  }
}
