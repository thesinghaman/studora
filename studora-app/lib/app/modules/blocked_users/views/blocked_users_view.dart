import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/modules/blocked_users/controllers/blocked_users_controller.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/detailed_list_item_shimmer_card.dart';
class BlockedUsersView extends GetView<BlockedUsersController> {
  const BlockedUsersView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Blocked Users")),
      body: Obx(() {
        if (controller.isLoading.value) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) =>
                const DetailedListItemShimmerCard(),
          );
        }
        if (controller.blockedUsersList.isEmpty) {
          return Center(
            child: Text(
              "You haven't blocked any users.",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: controller.blockedUsersList.length,
          itemBuilder: (context, index) {
            final user = controller.blockedUsersList[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.userAvatarUrl != null && user.userAvatarUrl!.isNotEmpty
                    ? NetworkImage(user.userAvatarUrl!)
                    : null,
                child: user.userAvatarUrl == null || user.userAvatarUrl!.isEmpty
                    ? Text(user.getInitials())
                    : null,
              ),
              title: Text(user.userName),
              subtitle: user.email == "private" ? null : Text(user.email),
              onTap: () => controller.navigateToDetail(user),
            );
          },
        );
      }),
    );
  }
}
