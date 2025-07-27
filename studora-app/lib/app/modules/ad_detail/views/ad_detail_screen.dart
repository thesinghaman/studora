import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/modules/ad_detail/controllers/ad_detail_controller.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class AdDetailScreen extends GetView<AdDetailController> {
  const AdDetailScreen({super.key});
  Widget _buildAdDetailShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerBaseColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final shimmerHighlightColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[100]!;
    final shimmerPlaceholderColor =
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
            .withValues(alpha: 0.07);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.8,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
        title: Shimmer.fromColors(
          baseColor: shimmerBaseColor,
          highlightColor: shimmerHighlightColor,
          child: Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: shimmerPlaceholderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        actions: [
          Shimmer.fromColors(
            baseColor: shimmerBaseColor,
            highlightColor: shimmerHighlightColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Shimmer.fromColors(
        baseColor: shimmerBaseColor,
        highlightColor: shimmerHighlightColor,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
              ),
              Container(
                height: 28,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 6),
              ),
              Container(
                height: 28,
                width: Get.width * 0.6,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 12),
              ),
              Row(
                children: [
                  Container(
                    height: 32,
                    width: 120,
                    decoration: BoxDecoration(
                      color: shimmerPlaceholderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 32,
                    width: 100,
                    decoration: BoxDecoration(
                      color: shimmerPlaceholderColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: shimmerPlaceholderColor,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 100,
                        decoration: BoxDecoration(
                          color: shimmerPlaceholderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        margin: const EdgeInsets.only(bottom: 5),
                      ),
                      Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                          color: shimmerPlaceholderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 30),
              _buildShimmerInfoRow(shimmerPlaceholderColor),
              _buildShimmerInfoRow(
                shimmerPlaceholderColor,
                width1: 110,
                width2: 160,
              ),
              const SizedBox(height: 18),
              Container(
                height: 20,
                width: 130,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 10),
              ),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 6),
              ),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 6),
              ),
              Container(
                height: 14,
                width: Get.width * 0.75,
                decoration: BoxDecoration(
                  color: shimmerPlaceholderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildShimmerInfoRow(
    Color placeholderColor, {
    double width1 = 90,
    double width2 = 130,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: placeholderColor, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: width1,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 6),
                ),
                Container(
                  height: 14,
                  width: width2,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value, {
    bool isChip = false,
    Color? chipColor,
    bool isStrong = false,
  }) {
    final theme = Theme.of(context);
    if (value == null || value.isEmpty || value == 'N/A') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
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
                isChip
                    ? Chip(
                        label: Text(
                          value,
                          style: TextStyle(
                            color: chipColor ?? theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor:
                            (chipColor ?? theme.colorScheme.primary).withValues(
                              alpha: 0.1,
                            ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                      )
                    : Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: isStrong
                              ? FontWeight.w600
                              : FontWeight.normal,
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
    final ad = controller.rxAd.value;
    if (ad == null) return const SizedBox.shrink();
    final images = ad.imageUrls;
    if (images == null || images.isEmpty) {
      return Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.photo_camera_solid,
            size: 60,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    final shimmerBaseColor = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final shimmerHighlightColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[100]!;
    final shimmerPlaceholderColor =
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
            .withValues(alpha: 0.07);
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (images.isNotEmpty) {
              Get.toNamed(
                AppRoutes.FULLSCREEN_IMAGE_VIEWER,
                arguments: {
                  'images': images.map((e) => e.toString()).toList(),
                  'initialIndex': controller.currentImageIndex,
                },
              );
            }
          },
          child: Container(
            height: 280,
            margin: EdgeInsets.only(bottom: images.length > 1 ? 0 : 16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: PageView.builder(
                controller: controller.imagePageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  controller.currentImageIndex = index;
                },
                itemBuilder: (context, index) {
                  final imagePath = images[index];
                  return Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: shimmerBaseColor,
                        highlightColor: shimmerHighlightColor,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: shimmerPlaceholderColor,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        color: Colors.redAccent,
                        size: 40,
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
            padding: const EdgeInsets.only(top: 10.0, bottom: 16.0),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (idx) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: controller.currentImageIndex == idx ? 24.0 : 8.0,
                    decoration: BoxDecoration(
                      color: controller.currentImageIndex == idx
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),
          ),
      ],
    );
  }
  void _showOwnerActionsModal(
    BuildContext context,
    ThemeData theme,
    ItemModel ad,
  ) {
    if (controller.rxAd.value == null) return;
    bool isCurrentlyExpiredByDate = ad.expiryDate.isBefore(DateTime.now());
    bool isPermanentlyClosed = ad.adStatus == "Sold" || ad.adStatus == "Rented";
    List<Widget> actions = [];
    if (isPermanentlyClosed) {
      actions.add(
        ListTile(
          leading: Icon(
            CupertinoIcons.delete_solid,
            color: theme.colorScheme.error,
            size: 24,
          ),
          title: Text(
            'Delete Ad',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Get.back();
            _confirmDeleteAdDialog(context, theme);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: theme.colorScheme.error.withValues(alpha: 0.08),
        ),
      );
    } else {
      actions.add(
        ListTile(
          leading: Icon(
            Icons.edit_note_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          title: Text(
            'Edit Ad',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: () {
            Get.back();
            controller.editAd();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        ),
      );
      actions.add(const SizedBox(height: 8));
      if (ad.isActive && !isCurrentlyExpiredByDate) {
        actions.add(
          ListTile(
            leading: Icon(
              CupertinoIcons.check_mark,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            title: Text(
              ad.isRental ? 'Mark as Rented' : 'Mark as Sold',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.markAsSoldOrRented();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
        actions.add(const SizedBox(height: 8));
        actions.add(
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
              controller.makeAdInactive();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.secondary.withValues(alpha: 0.08),
          ),
        );
      } else if (!ad.isActive && !isPermanentlyClosed) {
        actions.add(
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
              controller.makeAdActiveAgain(
                forceExtendExpiry: isCurrentlyExpiredByDate,
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
      } else if (isCurrentlyExpiredByDate && !isPermanentlyClosed) {
        actions.add(
          ListTile(
            leading: Icon(
              Icons.restart_alt_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            title: Text(
              'Relist Ad (Extend Expiry)',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              controller.makeAdActiveAgain(forceExtendExpiry: true);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            tileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
        );
      }
      if (!isPermanentlyClosed) {
        actions.add(const SizedBox(height: 8));
        actions.add(
          ListTile(
            leading: Icon(
              CupertinoIcons.delete_solid,
              color: theme.colorScheme.error,
              size: 22,
            ),
            title: Text(
              'Delete Ad',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Get.back();
              _confirmDeleteAdDialog(context, theme);
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
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Manage Your Ad",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Choose an action to perform on your listing.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...actions,
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
  void _confirmDeleteAdDialog(BuildContext context, ThemeData theme) {
    Get.dialog(
      AlertDialog(
        title: Text(
          "Delete Ad?",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this ad? This action cannot be undone.",
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
              controller.confirmDeleteAd();
            },
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildAdDetailShimmer(context);
      }
      final ad = controller.rxAd.value;
      if (ad == null) {
        return Scaffold(
          appBar: AppBar(title: const Text("Error Loading Ad")),
          body: const Center(child: Text("Ad details could not be loaded.")),
        );
      }
      final Color primaryColor = theme.colorScheme.primary;
      final NumberFormat currencyFormatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: controller.currencySymbol,
        decimalDigits: (ad.price.truncateToDouble() == ad.price) ? 0 : 2,
      );
      final isDisplayExpired = ad.expiryDate.isBefore(DateTime.now());
      final isSoldOrRented = ad.adStatus == "Sold" || ad.adStatus == "Rented";
      String displayStatusText;
      Color displayStatusColor;
      IconData displayStatusIcon;
      if (isSoldOrRented) {
        displayStatusText = ad.adStatus;
        displayStatusColor = Colors.blueGrey.shade600;
        displayStatusIcon = CupertinoIcons.check_mark_circled_solid;
      } else if (!ad.isActive) {
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
      final String fabText = ad.isRental
          ? "Chat with Lister"
          : "Chat with Seller";
      const IconData fabIcon = CupertinoIcons.chat_bubble_2_fill;
      final bool showFabLayout =
          !controller.isOwner &&
          ad.isActive &&
          !isDisplayExpired &&
          !isSoldOrRented;
      final double fabHeightPlusMargin = 56.0 + 16.0 + 24.0;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            ad.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0.8,
          surfaceTintColor: theme.scaffoldBackgroundColor,
          actions: [
            if (!controller.isOwner && showFabLayout)
              Obx(
                () => IconButton(
                  icon: Icon(
                    controller.isFavorite
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: controller.isFavorite
                        ? Colors.redAccent
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: "Wishlist",
                  onPressed: controller.toggleFavorite,
                ),
              ),
            if (!controller.isOwner && showFabLayout)
              Obx(
                () => controller.isCheckingReportStatus.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: CupertinoActivityIndicator(),
                      )
                    : IconButton(
                        icon: Icon(
                          CupertinoIcons.flag,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        tooltip: "Report Ad",
                        onPressed: controller.navigateToReportAd,
                      ),
              ),
            if (controller.isOwner)
              IconButton(
                icon: Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: "More Options",
                onPressed: () => _showOwnerActionsModal(context, theme, ad),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.isOwner)
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
              Text(
                ad.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    currencyFormatter.format(ad.price) +
                        (ad.isRental ? " ${ad.rentalTerm ?? '/ month'}" : ""),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    avatar: Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    label: Obx(
                      () => Text(
                        controller.rxCategoryName.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (!ad.isRental &&
                  ad.condition != null &&
                  ad.condition != ItemCondition.notApplicable) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  CupertinoIcons.checkmark_shield_fill,
                  "Condition",
                  controller.itemConditionToString(ad.condition),
                ),
              ],
              if (!isSoldOrRented)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: _buildInfoRow(
                    context,
                    CupertinoIcons.timer,
                    "Expires On",
                    DateFormat('MMM d, hh:mm a').format(ad.expiryDate),
                    isStrong: isDisplayExpired,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        ad.sellerProfilePicUrl != null &&
                            ad.sellerProfilePicUrl!.startsWith('http')
                        ? NetworkImage(ad.sellerProfilePicUrl!)
                        : null,
                    backgroundColor: theme.colorScheme.surfaceContainerLowest,
                    child:
                        ad.sellerProfilePicUrl == null ||
                            !ad.sellerProfilePicUrl!.startsWith('http')
                        ? Icon(
                            CupertinoIcons.person_fill,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.sellerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Posted on: ${DateFormat('MMM d, yyyy').format(ad.datePosted)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(
                context,
                CupertinoIcons.location_solid,
                "Location",
                ad.location,
              ),
              if (ad.isRental) ...[
                if (ad.availableFrom != null)
                  _buildInfoRow(
                    context,
                    CupertinoIcons.calendar_badge_plus,
                    "Available From",
                    DateFormat('MMM d, yyyy').format(ad.availableFrom!),
                  ),
                if (ad.propertyType != null && ad.propertyType!.isNotEmpty)
                  _buildInfoRow(
                    context,
                    CupertinoIcons.house_fill,
                    "Property Type",
                    ad.propertyType!,
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                "Description",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ad.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (ad.isRental &&
                  ad.amenities != null &&
                  ad.amenities!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  "Amenities",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: ad.amenities!
                      .map(
                        (amenity) => Chip(
                          label: Text(
                            amenity,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              SizedBox(height: showFabLayout ? fabHeightPlusMargin : 20),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() {
          final ad = controller.rxAd.value;

          if (ad == null) return const SizedBox.shrink();
          final bool actualShowFabForAnimation =
              !controller.isOwner &&
              ad.isActive &&
              !(ad.expiryDate.isBefore(DateTime.now())) &&
              !(ad.adStatus == "Sold" || ad.adStatus == "Rented");
          return AnimatedOpacity(
            opacity: actualShowFabForAnimation ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: actualShowFabForAnimation
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FloatingActionButton.extended(
                        onPressed: controller.isLoadingChatInitiation.value
                            ? null
                            : controller.initiateChat,
                        icon: controller.isLoadingChatInitiation.value
                            ? CupertinoActivityIndicator(
                                color: theme.colorScheme.onPrimary,
                              )
                            : const Icon(fabIcon, size: 20),
                        label: Text(
                          fabText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      );
    });
  }
}
