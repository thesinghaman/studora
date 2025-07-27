import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/my_ads/controllers/my_ads_controller.dart';
import 'package:studora/app/shared_components/widgets/custom_segmented_control.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/modules/my_ads/widgets/my_ad_list_item_card.dart';
import 'package:studora/app/shared_components/widgets/minimal_lost_found_item_card.dart';

class MyAdsView extends GetView<MyAdsController> {
  const MyAdsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            CustomSegmentedControl(
              segments: const ["Listed Items", "Rentals", "Lost & Found"],
              selectedIndex: controller.selectedTabIndex.value,
              onSegmentTapped: (index) {
                controller.tabController.animateTo(index);
              },
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  _buildTabContent(
                    context,
                    child: _buildSectionedItemsList(context, isRental: false),
                  ),
                  _buildTabContent(
                    context,
                    child: _buildSectionedItemsList(context, isRental: true),
                  ),
                  _buildTabContent(
                    context,
                    child: _buildSectionedLostFoundList(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      leading: controller.isSelectionMode.value
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.cancelSelectionMode,
            )
          : null,
      title: Text(
        controller.isSelectionMode.value
            ? '${controller.selectedItemIds.length} selected'
            : 'My Listings',
      ),
      actions: controller.isSelectionMode.value
          ? [
              TextButton(
                onPressed: controller.toggleSelectAllInCurrentTab,
                child: Text(
                  controller.areAllItemsInCurrentTabSelected
                      ? "Deselect All"
                      : "Select All",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.delete),
                onPressed: () => _showConfirmDeleteBottomSheet(context),
              ),
            ]
          : [],
      elevation: 0.5,
    );
  }

  void _showConfirmDeleteBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    Get.bottomSheet(
      Container(
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Confirm Deletion',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete the selected ${controller.selectedItemIds.length} item(s)? This action cannot be undone.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("CANCEL"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () {
                      Get.back();
                      controller.deleteSelectedItems();
                    },
                    child: const Text("DELETE"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildTabContent(BuildContext context, {required Widget child}) {
    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CupertinoActivityIndicator(radius: 15))
          : RefreshIndicator(
              onRefresh: controller.refreshAllData,
              child: child,
            ),
    );
  }

  Widget _buildSectionedItemsList(
    BuildContext context, {
    required bool isRental,
  }) {
    final active = isRental
        ? controller.activeRentalAds
        : controller.activeListedAds;
    final inactive = isRental
        ? controller.inactiveRentalAds
        : controller.inactiveListedAds;
    final expired = isRental
        ? controller.expiredRentalAds
        : controller.expiredListedAds;
    final closed = isRental
        ? controller.soldOrRentedRentalAds
        : controller.soldOrRentedListedAds;
    final sectionPrefix = isRental ? 'rental_' : 'listed_';
    if (active.isEmpty &&
        inactive.isEmpty &&
        expired.isEmpty &&
        closed.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildEmptyState(
            isRental
                ? "You have no rental listings."
                : "You have no items listed for sale.",
            "Post something to see it here!",
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      children: [
        if (active.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Active (${active.length})",
            items: active,
            expansionKey: '${sectionPrefix}active',
          ),
        if (inactive.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Inactive (${inactive.length})",
            items: inactive,
            expansionKey: '${sectionPrefix}inactive',
            defaultExpanded: false,
          ),
        if (expired.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Expired (${expired.length})",
            items: expired,
            expansionKey: '${sectionPrefix}expired',
            defaultExpanded: false,
          ),
        if (closed.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: isRental
                ? "Rented (${closed.length})"
                : "Sold (${closed.length})",
            items: closed,
            expansionKey: '$sectionPrefix${isRental ? "rented" : "sold"}',
            defaultExpanded: false,
          ),
      ],
    );
  }

  Widget _buildSectionedLostFoundList(BuildContext context) {
    final active = controller.activeLostFoundPosts,
        inactive = controller.inactiveLostFoundPosts,
        expired = controller.expiredLostFoundPosts,
        resolved = controller.resolvedLostFoundPosts;
    if (active.isEmpty &&
        inactive.isEmpty &&
        expired.isEmpty &&
        resolved.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildEmptyState(
            "You haven't reported any lost or found items.",
            "Find or lose something to see it here!",
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      children: [
        if (active.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Active (${active.length})",
            items: active,
            expansionKey: 'lf_active',
          ),
        if (inactive.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Inactive (${inactive.length})",
            items: inactive,
            expansionKey: 'lf_inactive',
            defaultExpanded: false,
          ),
        if (expired.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Expired (${expired.length})",
            items: expired,
            expansionKey: 'lf_expired',
            defaultExpanded: false,
          ),
        if (resolved.isNotEmpty)
          _buildCollapsibleSection(
            context,
            title: "Resolved (${resolved.length})",
            items: resolved,
            expansionKey: 'lf_resolved',
            defaultExpanded: false,
          ),
      ],
    );
  }

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required List<dynamic> items,
    required String expansionKey,
    bool defaultExpanded = true,
  }) {
    final theme = Theme.of(context);
    final isExpanded =
        controller.isExpanded[expansionKey]?.value ?? defaultExpanded;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          InkWell(
            onTap: () => controller.toggleExpansion(expansionKey),
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isExpanded
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (ctx, index) {
                final item = items[index];
                final String itemId = item is ItemModel
                    ? item.id
                    : (item as LostFoundItemModel).id!;
                if (item is ItemModel) {
                  return MyAdListItemCard(
                    item: item,
                    isSelectionMode: controller.isSelectionMode.value,
                    isSelected: controller.selectedItemIds.contains(itemId),
                    onTap: () => controller.onItemTap(item),
                    onLongPress: () => controller.onItemLongPress(itemId),
                  );
                } else if (item is LostFoundItemModel) {
                  return MinimalLostFoundItemCard(
                    item: item,
                    isSelectionMode: controller.isSelectionMode.value,
                    isSelected: controller.selectedItemIds.contains(itemId),
                    getCategoryIconById: controller.getCategoryIconById,
                    onTapItem: () => controller.onItemTap(item),
                    onLongPressItem: () => controller.onItemLongPress(itemId),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.tray_fill,
              size: 60,
              color: Theme.of(
                Get.context!,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                Get.context!,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(Get.context!).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
