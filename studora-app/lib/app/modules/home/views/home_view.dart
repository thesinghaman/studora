import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'package:studora/app/modules/home/controllers/home_controller.dart';
import 'package:studora/app/services/wishlist_service.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
import 'package:studora/app/shared_components/widgets/ad_card_widget.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/home_header_shimmer_widget.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/ad_card_shimmer_widget.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/category_card_shimmer_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: isDarkMode ? 0.9 : 1.0),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkMode ? 0.07 : 0.035,
                ),
                blurRadius: 8.0,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 5.0),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGridItem(BuildContext context, CategoryModel category) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (category.id.toLowerCase() == 'housing' ||
            category.type.toLowerCase() == 'rental') {
          controller.navigateToAllRentals();
        } else {
          controller.navigateToCategoryListings(category.id, category.name);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.1
                    : 0.05,
              ),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              controller.getIconForCategory(category.iconId),
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final Color shimmerBaseC = theme.brightness == Brightness.dark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final Color shimmerHighlightC = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[100]!;
    final Color shimmerPlaceholderC = Colors.white;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: <Widget>[
              const SliverToBoxAdapter(child: HomeHeaderShimmerWidget()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
                  child: Shimmer.fromColors(
                    baseColor: shimmerBaseC,
                    highlightColor: shimmerHighlightC,
                    child: Container(
                      height: 24,
                      width: 220,
                      decoration: BoxDecoration(
                        color: shimmerPlaceholderC,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio:
                        ((MediaQuery.of(context).size.width - (16 * 2) - 12) /
                            2) /
                        (((MediaQuery.of(context).size.width - (16 * 2) - 12) /
                                2) *
                            1.5),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const AdCardShimmerWidget(),
                    childCount: 4,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                  child: Shimmer.fromColors(
                    baseColor: shimmerBaseC,
                    highlightColor: shimmerHighlightC,
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerPlaceholderC,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 10.0),
                  child: Shimmer.fromColors(
                    baseColor: shimmerBaseC,
                    highlightColor: shimmerHighlightC,
                    child: Container(
                      height: 24,
                      width: 180,
                      decoration: BoxDecoration(
                        color: shimmerPlaceholderC,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.95,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const CategoryCardShimmerWidget(),
                    childCount: 6,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  height: statusBarHeight,
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    return Obx(() {
      if (controller.isLoading && controller.recentMarketplaceItems.isEmpty) {
        return _buildLoadingShimmer(context);
      }
      return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refreshData,
              color: primaryColor,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    expandedHeight: 300.0,
                    floating: false,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Padding(
                        padding: EdgeInsets.only(top: statusBarHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16.0,
                                10.0,
                                8.0,
                                0.0,
                              ),
                              child: AnimatedFadeSlide(
                                delay: const Duration(milliseconds: 50),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Obx(
                                            () => Text(
                                              "Hi ${controller.currentUserFirstName.value}!",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            "What are you up to today?",
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                  height: 1.25,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        CupertinoIcons.heart,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        size: 24,
                                      ),
                                      onPressed: controller.navigateToWishlist,
                                      tooltip: "Wishlist",
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: AnimatedFadeSlide(
                                delay: const Duration(milliseconds: 100),
                                child: GestureDetector(
                                  onTap: controller.navigateToSearch,
                                  child: AbsorbPointer(
                                    child: CupertinoSearchTextField(
                                      placeholder: "Search anything...",
                                      enabled: false,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(fontSize: 15.0),
                                      itemColor: isDarkMode
                                          ? Colors.grey[400]!
                                          : Colors.grey[700]!,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: AnimatedFadeSlide(
                                delay: const Duration(milliseconds: 150),
                                child: Row(
                                  children: [
                                    _buildQuickActionCard(
                                      context,
                                      title: "Post Ad",
                                      icon: CupertinoIcons.add_circled_solid,
                                      iconBackgroundColor: primaryColor,
                                      iconColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      onTap: controller.navigateToPostAd,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildQuickActionCard(
                                      context,
                                      title: "Lost & Found",
                                      icon: CupertinoIcons.archivebox_fill,
                                      iconBackgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      iconColor: isDarkMode
                                          ? Colors.black
                                          : Colors.white,
                                      onTap: controller.navigateToLostAndFound,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: AnimatedFadeSlide(
                                delay: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: Icon(
                                      CupertinoIcons.house_alt_fill,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                                    label: Text(
                                      "Browse Rentals",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.secondaryContainer,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                      ),
                                      elevation: 1.0,
                                    ),
                                    onPressed: controller.navigateToAllRentals,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
                      child: AnimatedFadeSlide(
                        delay: const Duration(milliseconds: 250),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Recent Marketplace Items",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => _buildRecentMarketplaceGrid(
                      context,
                      controller.recentMarketplaceItems.toList(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                      child: ElevatedButton(
                        onPressed: controller.navigateToAllMarketplaceItems,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("View All Marketplace Items"),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Text(
                        "Browse by Category",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
                      sliver:
                          controller.homeScreenCategories.isEmpty &&
                              !controller.isLoading
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 30.0,
                                  ),
                                  child: Text(
                                    "No categories found.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            )
                          : (controller.homeScreenCategories.isEmpty &&
                                    controller.isLoading
                                ? const SliverToBoxAdapter(
                                    child: SizedBox.shrink(),
                                  )
                                : SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 12.0,
                                          mainAxisSpacing: 12.0,
                                          childAspectRatio: 0.95,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (BuildContext context, int index) {
                                        return _buildCategoryGridItem(
                                          context,
                                          controller
                                              .homeScreenCategories[index],
                                        );
                                      },
                                      childCount: controller
                                          .homeScreenCategories
                                          .length,
                                    ),
                                  )),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                  child: Container(
                    height: statusBarHeight,
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecentMarketplaceGrid(
    BuildContext context,
    List<ItemModel> items,
  ) {
    final WishlistService wishlistService = Get.find<WishlistService>();
    if (items.isEmpty && !controller.isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.cube_box,
                  size: 50,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent marketplace items found.",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  "Pull to refresh or check back later.",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio:
              ((MediaQuery.of(context).size.width - (16 * 2) - 12) / 2) /
              (((MediaQuery.of(context).size.width - (16 * 2) - 12) / 2) * 1.5),
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return AnimatedFadeSlide(
            delay: Duration(milliseconds: 50 * (index % 8) + 50),
            offset: const Offset(0, 0.02),
            duration: const Duration(milliseconds: 300),
            child: Obx(
              () => AdCardWidget(
                item: item,
                isFavorite: wishlistService.favoriteItemIds.contains(item.id),
                onFavoriteTap:
                    item.sellerId == controller.currentLoggedInUserId.value
                    ? null
                    : () => wishlistService.toggleFavorite(item.id),
                currentLoggedInUserId: controller.currentLoggedInUserId.value,
                isUserAd:
                    item.sellerId == controller.currentLoggedInUserId.value,
              ),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }
}
