import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/message_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/modules/individual_chat/controllers/individual_chat_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class IndividualChatView extends GetView<IndividualChatController> {
  const IndividualChatView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: Column(
        children: [
          Obx(() {
            if (controller.fullRelatedItems.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildRelatedItemBanner(
              context,
              controller.fullRelatedItems.toList(),
              theme,
            );
          }),

          Expanded(
            child: GetBuilder<IndividualChatController>(
              builder: (ctl) {
                if (ctl.isLoading) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (ctl.chatListItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No messages yet. Say hello! 👋",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  controller: ctl.scrollController,
                  itemCount: ctl.chatListItems.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  itemBuilder: (context, index) {
                    final item = ctl.chatListItems[index];
                    if (item is DateTime) {
                      return _buildDateSeparator(item, theme);
                    } else if (item is MessageModel) {
                      final bool isCurrentUser =
                          item.senderId == ctl.currentUserId;
                      return _MessageBubble(
                        key: ValueKey(item.id),
                        message: item,
                        isCurrentUser: isCurrentUser,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
          _buildMessageInputArea(theme, context),
        ],
      ),
    );
  }

  void _showMultipleItemsBottomSheet(
    BuildContext context,
    List<dynamic> items,
    ThemeData theme,
  ) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Discussed Items', style: theme.textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                separatorBuilder: (context, index) =>
                    const Divider(indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return _RelatedItemCardForBottomSheet(
                    item: item,
                    theme: theme,
                    onTap: () {
                      Get.back();
                      _handleItemTap(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
            ? "You have deleted this item, so it is no longer visible to others."
            : "This item has been deleted by the owner.",
      );
      return;
    }

    if (!item.isActive) {
      _showStatusModal(
        message: isTapperTheOwner
            ? "You marked this item as inactive. Visit the 'My Ads' section to make it active again."
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
        'originatingConversationId': controller.conversation?.id,
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

  Widget _buildRelatedItemBanner(
    BuildContext context,
    List<dynamic> items,
    ThemeData theme,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    final primaryItem = items.first;
    final additionalItemsCount = items.length > 1 ? items.length - 1 : 0;

    final String? imageUrl;
    if (primaryItem is RelatedItem) {
      imageUrl = primaryItem.imageUrl;
    } else {
      imageUrl = primaryItem.imageUrls?.isNotEmpty == true
          ? primaryItem.imageUrls!.first
          : null;
    }

    final String title = primaryItem.title;
    final bool isMarketplaceAd =
        primaryItem is ItemModel ||
        (primaryItem is RelatedItem && primaryItem.itemType == 'ItemModel');
    final String subtitle = isMarketplaceAd
        ? (primaryItem is ItemModel
              ? NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '₹',
                  decimalDigits: 0,
                ).format(primaryItem.price)
              : 'Marketplace Item')
        : (primaryItem is LostFoundItemModel
              ? (primaryItem.type == LostFoundType.lost
                    ? "Lost Item"
                    : "Found Item")
              : 'Lost & Found Item');
    final Color subtitleColor = isMarketplaceAd
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () {
          if (items.length > 1) {
            _showMultipleItemsBottomSheet(context, items, theme);
          } else {
            _handleItemTap(primaryItem);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  color: theme.colorScheme.surface,
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.error),
                      )
                    : Icon(
                        isMarketplaceAd
                            ? CupertinoIcons.cube_box
                            : CupertinoIcons.question_diamond,
                        size: 20,
                        color: theme.hintColor,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (additionalItemsCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$additionalItemsCount',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      elevation: 0.5,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: controller.navigateToChatUserProfile,
        child: Row(
          children: [
            GetBuilder<IndividualChatController>(
              builder: (ctl) {
                return CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      ctl.otherUserAvatarUrl != null &&
                          ctl.otherUserAvatarUrl!.startsWith('http')
                      ? NetworkImage(ctl.otherUserAvatarUrl!)
                      : null,
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.7),
                  child:
                      (ctl.otherUserAvatarUrl == null ||
                          !ctl.otherUserAvatarUrl!.startsWith('http'))
                      ? Text(
                          ctl.otherUserName.isNotEmpty
                              ? ctl.otherUserName[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.otherUserName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  GetBuilder<IndividualChatController>(
                    builder: (ctl) {
                      if (ctl.formattedLastSeen.isNotEmpty) {
                        return Text(
                          ctl.formattedLastSeen,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: ctl.isOtherUserOnline
                                ? Colors.green.shade400
                                : theme.colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.7,
                                  ),
                            fontSize: 11.5,
                            height: 1.2,
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Obx(() {
          final isBlocked = controller.isBlockedByMe.value;
          final isDeleting = controller.isDeleting.value;
          if (isDeleting) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoActivityIndicator(),
            );
          }
          return PopupMenuButton<String>(
            tooltip: "More Options",
            onSelected: (value) {
              if (value == 'block') {
                controller.blockUser();
              } else if (value == 'unblock') {
                controller.unblockUser();
              } else if (value == 'delete') {
                controller.deleteConversation();
              }
            },
            itemBuilder: (BuildContext context) => [
              if (isBlocked)
                const PopupMenuItem<String>(
                  value: 'unblock',
                  child: Text('Unblock User'),
                )
              else
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Text('Block User'),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Conversation'),
              ),
            ],
            icon: Icon(
              CupertinoIcons.ellipsis_vertical,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageInputArea(ThemeData theme, BuildContext context) {
    return Obx(() {
      if (controller.isBlockedByMe.value) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          color: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You've blocked this user and cannot send further messages.",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.unblockUser,
                child: const Text("Unblock User"),
              ),
            ],
          ),
        );
      }
      return Material(
        color: theme.scaffoldBackgroundColor,
        elevation: 8.0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    CupertinoIcons.photo_on_rectangle,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => controller.pickAndSendImages(),
                  tooltip: "Attach Image",
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 4.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    child: TextField(
                      controller: controller.textController,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GetBuilder<IndividualChatController>(
                  builder: (ctl) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: ctl.isComposing ? 48.0 : 0.0,
                      child: ctl.isComposing
                          ? IconButton(
                              icon: Icon(
                                CupertinoIcons.arrow_up_circle_fill,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                              onPressed: () => ctl.sendMessage(),
                              tooltip: "Send Message",
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDateSeparator(DateTime date, ThemeData theme) {
    String text;
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      text = "Today";
    } else if (DateUtils.isSameDay(
      date,
      now.subtract(const Duration(days: 1)),
    )) {
      text = "Yesterday";
    } else {
      text = DateFormat('MMMM d, yyyy').format(date);
    }
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RelatedItemCardForBottomSheet extends StatelessWidget {
  final dynamic item;
  final ThemeData theme;
  final VoidCallback onTap;
  const _RelatedItemCardForBottomSheet({
    required this.item,
    required this.theme,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final String title;
    final String? imageUrl;
    final String subtitle;
    final Color subtitleColor;
    final bool isDeleted;
    final bool showInactiveOverlay;
    final bool isMarketplaceAd;
    if (item is RelatedItem) {
      isDeleted = true;
      showInactiveOverlay = false;
      title = item.title;
      imageUrl = item.imageUrl;
      subtitle = "This item was deleted";
      subtitleColor = theme.colorScheme.error;
      isMarketplaceAd = item.itemType == 'ItemModel';
    } else {
      isDeleted = false;
      title = item.title;
      imageUrl = item.imageUrls?.isNotEmpty == true
          ? item.imageUrls!.first
          : null;
      showInactiveOverlay = !item.isActive;
      isMarketplaceAd = item is ItemModel;
      if (isMarketplaceAd) {
        subtitle = NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ).format(item.price);
        subtitleColor = theme.colorScheme.primary;
      } else {
        subtitle = item.type == 'lost' ? "Lost Item" : "Found Item";
        subtitleColor = theme.colorScheme.secondary;
      }
    }
    return ListTile(
      onTap: onTap,
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: theme.colorScheme.surfaceContainer,
            ),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(Icons.error),
                  )
                : Icon(
                    isMarketplaceAd
                        ? CupertinoIcons.cube_box
                        : CupertinoIcons.question_diamond,
                    size: 24,
                    color: theme.hintColor,
                  ),
          ),
          if (showInactiveOverlay)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(
                CupertinoIcons.eye_slash_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: isDeleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: subtitleColor,
          fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }
}

class _MessageBubble extends GetView<IndividualChatController> {
  final MessageModel message;
  final bool isCurrentUser;
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isCurrentUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = isCurrentUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHigh;
    final textColor = isCurrentUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isCurrentUser
          ? const Radius.circular(18)
          : const Radius.circular(4),
      bottomRight: isCurrentUser
          ? const Radius.circular(4)
          : const Radius.circular(18),
    );
    final bool isOptimisticImage =
        message.localImageFiles != null && message.localImageFiles!.isNotEmpty;
    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(color: color, borderRadius: borderRadius),
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.type == MessageType.image)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImageGrid(
                      context,
                      isOptimisticImage,
                      message.localImageFiles,
                    ),
                  ),
                if (message.text != null && message.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                    child: Text(
                      message.text!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4.0,
                    right: 8.0,
                    bottom: 4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat.jm().format(message.timestamp.toLocal()),
                        style: TextStyle(
                          color: isCurrentUser
                              ? textColor.withValues(alpha: 0.8)
                              : theme.hintColor,
                          fontSize: 11.0,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (isCurrentUser)
                        controller.getStatusIcon(message.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (message.status == MessageStatus.failed && isCurrentUser)
            _buildStatusIcon(message),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(MessageModel message) {
    if (message.status == MessageStatus.failed) {
      return InkWell(
        onTap: () => controller.onFailedMessageTapped(message),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: controller.getStatusIcon(message.status),
        ),
      );
    } else {
      return controller.getStatusIcon(message.status);
    }
  }

  Widget _buildImageGrid(
    BuildContext context,
    bool isOptimistic,
    List<File>? localFiles,
  ) {
    final imageCount = isOptimistic
        ? localFiles!.length
        : (message.imageUrls?.length ?? 0);
    final images = isOptimistic ? localFiles : message.imageUrls;
    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      itemCount: imageCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: imageCount > 1 ? 2 : 1,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        Widget imageWidget;
        if (isOptimistic) {
          imageWidget = Image.file(images[index] as File, fit: BoxFit.cover);
        } else {
          imageWidget = GestureDetector(
            onTap: () {
              Get.toNamed(
                AppRoutes.FULLSCREEN_IMAGE_VIEWER,
                arguments: {
                  'images': images as List<String>,
                  'initialIndex': index,
                },
              );
            },
            child: Image.network(
              images[index] as String,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                return progress == null
                    ? child
                    : const Center(child: CupertinoActivityIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
          );
        }
        return imageWidget;
      },
    );
  }
}
