import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/modules/category_listings/controllers/category_listings_controller.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/modules/search/views/advanced_filter_view.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/widgets/detailed_list_item_card.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/detailed_list_item_shimmer_card.dart';
class CategoryListingsScreen extends GetView<CategoryListingsController> {
  final ScrollController _scrollController = ScrollController();
  CategoryListingsScreen({super.key}) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        controller.loadMoreItems();
      }
    });
  }
  void _showFilterPanel(BuildContext context) {
    Get.to(
      () => AdvancedFilterView(
        initialSortBy: controller.sortBy.value,
        initialCategoryIds: {},
        initialMinPrice: controller.minPrice.value,
        initialMaxPrice: controller.maxPrice.value,
        availableCategories: [],
        showCategoryFilter: false,
        onApplyFilters:
            ({
              required SortOption newSortBy,
              required Set<String> newCategoryIds,
              double? newMinPrice,
              double? newMaxPrice,
            }) {
              controller.applyFilters(
                newSortBy: newSortBy,
                newMinPrice: newMinPrice,
                newMaxPrice: newMaxPrice,
              );
            },
      ),
      fullscreenDialog: true,
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.categoryName),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.slider_horizontal_3,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                onPressed: () => _showFilterPanel(context),
                tooltip: "Filter & Sort",
              ),
              Obx(() {
                if (controller.activeFilterCount > 0) {
                  return Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${controller.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.handleRefresh,
        color: theme.colorScheme.primary,
        child: Column(
          children: [
            _buildSearchButton(context, theme),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return _buildLoadingShimmer();
                }
                if (controller.items.isEmpty) {
                  return _buildEmptyState(theme);
                }
                return _buildResultsList(theme);
              }),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.SEARCH),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Search all items and rentals...",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) => const DetailedListItemShimmerCard(),
    );
  }
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.tray_fill,
              size: 70,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              "No Items Found",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "There are no items matching your current filters in this category.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildResultsList(ThemeData theme) {
    return Obx(
      () => ListView.builder(
        controller: _scrollController,
        key: ValueKey('category_list_${controller.activeFilterCount}'),
        itemCount:
            controller.items.length + (controller.isLoadingMore.value ? 1 : 0),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 80.0),
        itemBuilder: (context, index) {
          if (index == controller.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final item = controller.items[index];
          final bool showDateSeparator = _shouldInsertDateSeparator(
            controller.items,
            index,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showDateSeparator)
                _buildMinimalDateSeparator(item.datePosted, theme),
              AnimatedFadeSlide(
                delay: Duration(milliseconds: 50 * (index % 15)),
                offset: const Offset(0, 0.02),
                child: Obx(
                  () => DetailedListItemCard(
                    item: item,
                    onTap: () => controller.onItemTap(item),
                    currentLoggedInUserId: controller.currentUserId ?? '',
                    isUserAd: item.sellerId == controller.currentUserId,
                    isFavorite: controller.isItemFavorite(item.id),
                    onFavoriteTap: item.sellerId == controller.currentUserId
                        ? null
                        : () => controller.toggleFavorite(item.id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildMinimalDateSeparator(DateTime date, ThemeData theme) {
    String formattedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDateComparable = DateTime(date.year, date.month, date.day);
    if (itemDateComparable == today) {
      formattedDate = "Today";
    } else if (itemDateComparable == yesterday) {
      formattedDate = "Yesterday";
    } else if (now.year == date.year) {
      formattedDate = DateFormat('MMMM d').format(date);
    } else {
      formattedDate = DateFormat('MMMM d, yyyy').format(date);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 8.0),
      child: Text(
        formattedDate,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }
  bool _shouldInsertDateSeparator(List<ItemModel> items, int currentIndex) {
    if (currentIndex == 0) return true;
    if (items.isEmpty || currentIndex >= items.length || currentIndex < 1) {
      return false;
    }
    final currentItemDate = items[currentIndex].datePosted;
    final previousItemDate = items[currentIndex - 1].datePosted;
    return !(currentItemDate.year == previousItemDate.year &&
        currentItemDate.month == previousItemDate.month &&
        currentItemDate.day == previousItemDate.day);
  }
}
