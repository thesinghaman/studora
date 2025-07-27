import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/models/user_profile_model.dart';
import 'package:studora/app/modules/chat_user_profile/controllers/chat_user_profile_controller.dart';
import 'package:studora/app/shared_components/widgets/mini_ad_display_card.dart';
import 'package:studora/app/shared_components/widgets/minimal_lost_found_item_card.dart';

class ChatUserProfileView extends GetView<ChatUserProfileController> {
  const ChatUserProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.userProfile.value?.userName ?? 'User Profile'),
        ),
        elevation: 0.5,
        actions: [
          Obx(() {
            final userName = controller.userProfile.value?.userName;
            if (userName == null) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(CupertinoIcons.flag, color: theme.colorScheme.error),
              tooltip: "More options for $userName",
              onPressed: () => _showBlockReportOptions(context, theme),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }
        final user = controller.userProfile.value;
        if (user == null) {
          return const Center(child: Text("User profile not found."));
        }
        return _buildProfileContent(user, context, theme);
      }),
    );
  }

  Widget _buildInactiveItemCard(BuildContext context, dynamic item) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Opacity(
        opacity: 0.6,
        child: ListTile(
          onTap: () => _handleItemTap(item),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 55,
                height: 55,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: item.imageUrls?.isNotEmpty == true
                    ? Image.network(
                        item.imageUrls!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.error),
                      )
                    : Icon(
                        item is ItemModel
                            ? CupertinoIcons.cube_box
                            : CupertinoIcons.question_diamond,
                      ),
              ),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.eye_slash_fill,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: const Text("Item is inactive"),
        ),
      ),
    );
  }

  void _handleItemTap(dynamic item) {
    final bool isDeleted = item is RelatedItem;

    final String currentUserId = controller.currentUserId;

    final String ownerId = isDeleted
        ? item.ownerId
        : (item is ItemModel ? item.sellerId : item.reporterId);

    final bool isTapperTheOwner = currentUserId == ownerId;
    if (isDeleted) {
      _showStatusModal(
        message: isTapperTheOwner
            ? "You have deleted this item. It is not visible to others."
            : "This item has been deleted by the owner.",
      );
      return;
    }

    if (!item.isActive) {
      _showStatusModal(
        message: isTapperTheOwner
            ? "You marked this item as inactive. Visit 'My Ads' to reactivate it."
            : "This item has been marked as inactive by the owner.",
      );
      return;
    }

    final bool isMarketplaceAd = item is ItemModel;
    Get.toNamed(
      isMarketplaceAd
          ? AppRoutes.ITEM_DETAIL
          : AppRoutes.LOST_FOUND_ITEM_DETAIL,
      arguments: {
        isMarketplaceAd ? 'ad' : 'post': item,
        'openedFromChatFlow': true,
        'originatingConversationId': controller.originatingConversationId,
      },
    );
  }

  void _showStatusModal({required String message}) {
    Get.dialog(
      AlertDialog(
        title: const Text('Item Unavailable'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    UserProfileModel user,
    BuildContext context,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: CircleAvatar(
            radius: 50,
            backgroundImage:
                user.isBlocked ||
                    user.userAvatarUrl == null ||
                    !user.userAvatarUrl!.startsWith('http')
                ? null
                : NetworkImage(user.userAvatarUrl!),
            child:
                user.isBlocked ||
                    user.userAvatarUrl == null ||
                    !user.userAvatarUrl!.startsWith('http')
                ? Text(
                    user.getInitials(),
                    style: theme.textTheme.headlineMedium,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16.0),
        Center(
          child: Text(
            user.userName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GetBuilder<ChatUserProfileController>(
          id: 'lastSeen',
          builder: (ctl) {
            if (ctl.formattedLastSeen.isEmpty || user.isBlocked) {
              return const SizedBox.shrink();
            }
            return Center(
              child: Text(
                ctl.formattedLastSeen,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: ctl.isOtherUserOnline.value
                      ? Colors.green.shade600
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
        if (!user.isBlocked) ...[
          if (user.email.isNotEmpty && user.email != 'private')
            Center(
              child: Text(
                user.email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12.0),
          const Divider(height: 24.0),
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
          if (user.dateJoined != null)
            _buildProfileDetailRow(
              context,
              CupertinoIcons.calendar_badge_plus,
              "Joined On",
              DateFormat('MMM d, yyyy').format(user.dateJoined!),
            ),
        ],
        const SizedBox(height: 16.0),
        const Divider(),
        const SizedBox(height: 10.0),

        Obx(() {
          if (controller.currentlyDiscussingItems.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currently Discussing:",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12.0),

              ListView.separated(
                itemCount: controller.currentlyDiscussingItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.currentlyDiscussingItems[index];

                  return _buildDiscussingItemCard(context, item);
                },
              ),
              const SizedBox(height: 16.0),
              const Divider(),
            ],
          );
        }),

        const SizedBox(height: 10.0),
        Obx(
          () => ListTile(
            leading: controller.isDeleting.value
                ? const CupertinoActivityIndicator()
                : Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            title: Text(
              "Delete Conversation",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: controller.isDeleting.value
                ? null
                : controller.deleteConversation,
          ),
        ),
        const SizedBox(height: 40.0),
      ],
    );
  }

  Widget _buildDiscussingItemCard(BuildContext context, dynamic item) {
    if (item is RelatedItem) {
      return _buildDeletedItemCard(context, item);
    }

    final bool isMarketplaceAd = item is ItemModel;
    final bool isActive = item.isActive;

    final String? status;
    if (isMarketplaceAd) {
      status = item.adStatus;
    } else {
      status = item.postStatus;
    }

    if (status == 'Deleted') {
      final relatedItemPlaceholder = RelatedItem(
        itemId: item.id,
        itemType: isMarketplaceAd ? 'ItemModel' : 'LostFoundItemModel',
        ownerId: isMarketplaceAd ? item.sellerId : item.reporterId,
        title: item.title,
        imageUrl: item.imageUrls?.isNotEmpty == true
            ? item.imageUrls!.first
            : null,
        createdAt: DateTime.now(),
      );
      return _buildDeletedItemCard(context, relatedItemPlaceholder);
    }

    if (!isActive) {
      return _buildInactiveItemCard(context, item);
    }

    if (isMarketplaceAd) {
      return MiniAdDisplayCard(
        adItem: item,
        onTapOverride: () => _handleItemTap(item),
      );
    } else {
      return MinimalLostFoundItemCard(
        item: item,
        getCategoryIconById: controller.getCategoryIcon,
        onTapItem: () => _handleItemTap(item),
      );
    }
  }

  void _showBlockReportOptions(BuildContext context, ThemeData theme) {
    Get.bottomSheet(
      Obx(
        () => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: Wrap(
            children: <Widget>[
              if (controller.isOtherUserBlocked.value) ...[
                ListTile(
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  title: const Text('Unblock User'),
                  onTap: () {
                    Get.back();
                    controller.unblockUser();
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.report,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('Report User'),
                  onTap: () {
                    Get.back();
                    controller.reportUser();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(
                    Icons.block,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('Block User'),
                  onTap: () {
                    Get.back();
                    controller.blockOnlyUser();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.report, color: theme.colorScheme.error),
                  title: Text(
                    'Block and Report User',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Get.back();
                    controller.blockAndReportUser();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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

  Widget _buildDeletedItemCard(BuildContext context, RelatedItem item) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => _handleItemTap(item),
        leading: Container(
          width: 55,
          height: 55,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: const Icon(
            CupertinoIcons.xmark_octagon_fill,
            color: Colors.grey,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: theme.disabledColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "This item was deleted",
          style: TextStyle(
            color: theme.colorScheme.error,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
