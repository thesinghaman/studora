import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:studora/app/modules/lost_found_detail/controllers/lost_found_detail_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class LostFoundDetailView extends GetView<LostFoundDetailController> {
  const LostFoundDetailView({super.key});

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    bool isContact = false,
    bool isStrong = false,
  }) {
    final theme = Theme.of(context);
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isContact
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurface,
                    height: 1.4,
                    fontWeight: isStrong
                        ? FontWeight.bold
                        : (isContact ? FontWeight.w600 : FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, ThemeData theme) {
    final item = controller.rxItemModel.value;
    final images = item.imageUrls;
    if (images == null || images.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: Icon(
            item.type == LostFoundType.lost
                ? CupertinoIcons.question_diamond_fill
                : CupertinoIcons.checkmark_shield_fill,
            size: 60,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    final shimmerBaseColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;
    final shimmerHighlightColor = theme.brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[100]!;
    return Column(
      children: [
        GestureDetector(
          onTap: controller.navigateToFullscreenViewer,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: PageView.builder(
                controller: controller.imagePageController,
                itemCount: images.length,
                onPageChanged: controller.onImageCarouselPageChanged,
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  return Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) => progress == null
                        ? child
                        : Shimmer.fromColors(
                            baseColor: shimmerBaseColor,
                            highlightColor: shimmerHighlightColor,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: shimmerBaseColor,
                            ),
                          ),
                    errorBuilder: (context, error, stack) => const Center(
                      child: Icon(
                        CupertinoIcons.photo_fill,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: controller.currentImageIndex.value == index
                        ? 24.0
                        : 8.0,
                    decoration: BoxDecoration(
                      color: controller.currentImageIndex.value == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),
          ),
        if (images.length == 1 && images.isNotEmpty)
          const SizedBox(height: 16 + 8 + 8),
      ],
    );
  }

  void _showOwnerActionsModal(BuildContext context, ThemeData theme) {
    final item = controller.rxItemModel.value;
    bool isCurrentlyExpiredByDate = item.expiryDate.isBefore(DateTime.now());
    bool isPermanentlyResolved =
        item.postStatus == "Reunited" || item.postStatus == "Returned";
    List<Widget> actionsListTiles = [];
    if (isPermanentlyResolved) {
      actionsListTiles.add(
        ListTile(
          leading: Icon(
            CupertinoIcons.delete_solid,
            color: theme.colorScheme.error,
            size: 24,
          ),
          title: Text(
            'Delete Post',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Get.back();
            _confirmDeletePostDialog(context, theme);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: theme.colorScheme.error.withValues(alpha: 0.08),
        ),
      );
    } else {
      actionsListTiles.add(
        ListTile(
          leading: Icon(
            Icons.edit_note_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          title: Text(
            'Edit Post',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Get.back();
            controller.editPost();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      );
      actionsListTiles.add(const SizedBox(height: 8));
      if (item.isActive && !isCurrentlyExpiredByDate) {
        actionsListTiles.add(
          ListTile(
            leading: Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            title: Text(
              item.type == LostFoundType.lost
                  ? 'Mark as Reunited'
                  : 'Mark as Item Returned',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.markAsResolved();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
        actionsListTiles.add(const SizedBox(height: 8));

        actionsListTiles.add(
          ListTile(
            leading: Icon(
              Icons.visibility_off_outlined,
              color: theme.colorScheme.secondary,
              size: 22,
            ),
            title: Text(
              'Make Inactive',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.makePostInactive();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.secondary.withValues(alpha: 0.08),
          ),
        );
      } else if (!item.isActive && !isPermanentlyResolved) {
        actionsListTiles.add(
          ListTile(
            leading: Icon(
              Icons.play_circle_outline_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              isCurrentlyExpiredByDate
                  ? 'Reactivate & Extend Expiry'
                  : 'Make Active',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.makePostActiveAgain(
                forceExtendExpiry: isCurrentlyExpiredByDate,
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
      } else if (isCurrentlyExpiredByDate && !isPermanentlyResolved) {
        actionsListTiles.add(
          ListTile(
            leading: Icon(
              Icons.restart_alt_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Reactivate & Extend Expiry',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.makePostActiveAgain(forceExtendExpiry: true);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
      }
      if (!isPermanentlyResolved) {
        actionsListTiles.add(const SizedBox(height: 8));
        actionsListTiles.add(
          ListTile(
            leading: Icon(
              CupertinoIcons.delete_solid,
              color: theme.colorScheme.error,
              size: 22,
            ),
            title: Text(
              'Delete Post',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              _confirmDeletePostDialog(context, theme);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.error.withValues(alpha: 0.08),
          ),
        );
      }
    }
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Manage Your Post",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Choose an action to perform on this Lost & Found post.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...actionsListTiles,
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
    );
  }

  void _confirmDeletePostDialog(BuildContext context, ThemeData theme) {
    Get.dialog(
      AlertDialog(
        title: Text(
          "Delete Post?",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this post? This action cannot be undone.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        backgroundColor: theme.colorScheme.surface,
        actionsPadding: const EdgeInsets.only(
          bottom: 16.0,
          left: 16.0,
          right: 16.0,
        ),
        actions: <Widget>[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            onPressed: () => Get.back(),
          ),
          ElevatedButton.icon(
            icon: const Icon(CupertinoIcons.delete_solid, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Get.back();
              controller.confirmDeletePost();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text("Loading Details...")),
          body: const Center(child: CupertinoActivityIndicator(radius: 15)),
        );
      }
      final item = controller.rxItemModel.value;
      final String itemTypeString = item.type == LostFoundType.lost
          ? "Lost"
          : "Found";
      final Color itemTypeStatusColor = item.type == LostFoundType.lost
          ? (isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700)
          : (isDarkMode ? Colors.green.shade300 : Colors.green.shade600);
      bool isDisplayExpired = item.expiryDate.isBefore(DateTime.now());
      bool isFinallyResolved =
          item.postStatus == "Reunited" || item.postStatus == "Returned";
      String displayStatusText;
      Color displayStatusColor;
      IconData displayStatusIcon;
      if (isFinallyResolved) {
        displayStatusText = item.postStatus;
        displayStatusColor = Colors.blueGrey.shade600;
        displayStatusIcon = CupertinoIcons.check_mark_circled_solid;
      } else if (!item.isActive) {
        displayStatusText = "Inactive";
        displayStatusColor = Colors.orange.shade700;
        displayStatusIcon = CupertinoIcons.xmark_circle_fill;
      } else if (isDisplayExpired) {
        displayStatusText = "Expired";
        displayStatusColor = theme.colorScheme.error;
        displayStatusIcon = CupertinoIcons.timer_fill;
      } else {
        displayStatusText = "Currently Active";
        displayStatusColor = Colors.green.shade600;
        displayStatusIcon = CupertinoIcons.checkmark_circle_fill;
      }
      final double fabHeightPlusMargin = 56.0 + 16.0 + 16.0;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            item.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0.8,
          surfaceTintColor: theme.scaffoldBackgroundColor,
          actions: controller.isOwner.value
              ? [
                  IconButton(
                    icon: const Icon(CupertinoIcons.ellipsis_vertical),
                    tooltip: "More Options",
                    onPressed: () => _showOwnerActionsModal(context, theme),
                  ),
                ]
              : (controller.showFab.value
                    ? [
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.flag,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: "Report Post",
                          onPressed: controller.reportPost,
                        ),
                        const SizedBox(width: 8),
                      ]
                    : null),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isOwner.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: displayStatusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          displayStatusIcon,
                          color: displayStatusColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayStatusText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: displayStatusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _buildImageCarousel(context, theme),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      itemTypeString.toUpperCase(),
                      style: TextStyle(
                        color: itemTypeStatusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    backgroundColor: itemTypeStatusColor.withValues(
                      alpha: 0.15,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Reported by: ${item.reporterName}",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isFinallyResolved)
                _buildDetailRow(
                  context,
                  CupertinoIcons.timer,
                  "Expires On",
                  DateFormat('MMM d, hh:mm a').format(item.expiryDate),
                  isStrong: isDisplayExpired,
                ),
              const SizedBox(height: 16),
              const Divider(),
              _buildDetailRow(
                context,
                CupertinoIcons.doc_text_fill,
                "Full Description",
                item.description,
              ),
              Obx(
                () => _buildDetailRow(
                  context,
                  CupertinoIcons.tag_fill,
                  "Category",
                  controller.categoryName.value,
                ),
              ),
              _buildDetailRow(
                context,
                CupertinoIcons.location_solid,
                item.type == LostFoundType.lost ? "Last Seen At" : "Found At",
                item.location,
              ),
              _buildDetailRow(
                context,
                CupertinoIcons.calendar,
                item.type == LostFoundType.lost
                    ? "Date Lost/Reported"
                    : "Date Found/Reported",
                DateFormat(
                  'EEEE, MMM d, yy',
                ).format(item.dateFoundOrLost ?? item.dateReported),
              ),
              if (item.dateFoundOrLost != null)
                _buildDetailRow(
                  context,
                  CupertinoIcons.time_solid,
                  item.type == LostFoundType.lost
                      ? "Approx. Time Lost"
                      : "Approx. Time Found",
                  DateFormat('h:mm a').format(item.dateFoundOrLost!),
                ),
              if (controller.showFab.value &&
                  (item.contactInfo?.isNotEmpty ?? false)) ...[
                const Divider(height: 32),
                Text(
                  "Contact / Details:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.contactInfo ?? '',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              Obx(
                () => SizedBox(
                  height: controller.showFab.value
                      ? fabHeightPlusMargin + 20
                      : 20,
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(
          () => controller.showFab.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FloatingActionButton.extended(
                      onPressed: controller.initiateChat,
                      icon: Icon(controller.primaryActionIcon.value, size: 20),
                      label: Text(
                        controller.primaryActionText.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
    });
  }
}
