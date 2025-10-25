import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/search/controllers/search_controller.dart';
import 'package:studora/app/modules/search/views/advanced_filter_view.dart';
import 'package:studora/app/shared_components/widgets/ad_card_widget.dart';
import 'package:studora/app/shared_components/widgets/custom_segmented_control.dart';

class SearchView extends GetView<ASearchController> {
  final ScrollController _scrollController = ScrollController();
  SearchView({super.key}) {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        controller.loadMoreResults();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        surfaceTintColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => CupertinoSearchTextField(
            controller: controller.searchTextController,
            focusNode: controller.searchFocusNode,
            placeholder: "Search items, rentals, etc.",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
            prefixIcon: controller.isDebouncing.value
                ? const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: CupertinoActivityIndicator(),
                  )
                : const Icon(CupertinoIcons.search, size: 22),
            itemColor: theme.colorScheme.onSurfaceVariant.withValues(
              alpha: 0.7,
            ),
            autofocus: true,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10.0),
            onSubmitted: controller.onSearchSubmitted,
            onSuffixTap: controller.clearSearchTextAndResubmit,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                  onPressed: () => _showFilterPanel(context),
                  tooltip: "Filter",
                ),
                Obx(() {
                  if (controller.activeFilterCount > 0) {
                    return Positioned(
                      top: 8,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.0,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        child: Center(
                          child: Text(
                            controller.activeFilterCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingInitialData.value) {
          return const Center(child: CupertinoActivityIndicator(radius: 15));
        }
        return Column(
          children: [
            if (controller.showTabsAndResultsHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: CustomSegmentedControl(
                  segments: const ["For Sale", "Rentals"],
                  selectedIndex: controller.selectedItemTypeTabIndex.value,
                  onSegmentTapped: (index) =>
                      controller.tabController.animateTo(index),
                ),
              )
            else
              const SizedBox(height: 8.0),
            Expanded(child: _buildSearchResultsBody(context)),
          ],
        );
      }),
    );
  }

  void _showFilterPanel(BuildContext context) {
    Get.to(
      () => AdvancedFilterView(
        initialSortBy: controller.sortBy.value,
        initialCategoryIds: controller.selectedCategoryIds,
        initialMinPrice: controller.minPrice.value,
        initialMaxPrice: controller.maxPrice.value,
        availableCategories: controller.currentCategoriesForFilterModal,
        onApplyFilters: controller.applyFiltersAndSearch,
      ),
      fullscreenDialog: true,
    );
  }

  Widget _buildSearchResultsBody(BuildContext context) {
    return Obx(() {
      if (controller.isPerformingSearch.value) {
        return const Center(child: CupertinoActivityIndicator(radius: 15));
      }
      if (!controller.hasPerformedSearchWithText.value &&
          !controller.hasActiveFilters) {
        return _buildRecentSearchesList(context);
      }
      return TabBarView(
        controller: controller.tabController,
        children: [
          _buildResultsGridForTab(context, isRentalTab: false),
          _buildResultsGridForTab(context, isRentalTab: true),
        ],
      );
    });
  }

  Widget _buildResultsGridForTab(
    BuildContext context, {
    required bool isRentalTab,
  }) {
    return Obx(() {
      final results = isRentalTab
          ? controller.rentalDisplayResults
          : controller.marketplaceDisplayResults;
      if (results.isEmpty) {
        return _buildEnhancedNoResultsPrompt(context, isRentalTab: isRentalTab);
      }
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.70,
        ),
        itemCount: results.length + (controller.isLoadingMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == results.length) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final item = results[index];
          return Obx(
            () => AdCardWidget(
              item: item,
              onTap: () => controller.onItemTap(item),
              isFavorite: controller.isItemFavorite(item.id),
              onFavoriteTap: () => controller.toggleFavorite(item.id),
              currentLoggedInUserId: controller.currentUserId ?? '',
              isUserAd: item.sellerId == controller.currentUserId,
            ),
          );
        },
      );
    });
  }

  Widget _buildRecentSearchesList(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return _buildInitialSearchPrompt(context);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Searches",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: controller.clearAllRecentSearches,
                  child: const Text("Clear All"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.recentSearches.length,
              itemBuilder: (context, index) {
                final term = controller.recentSearches[index];
                return ListTile(
                  leading: const Icon(CupertinoIcons.time),
                  title: Text(term),
                  onTap: () {
                    controller.searchTextController.text = term;
                    controller.onSearchSubmitted(term);
                  },
                  trailing: IconButton(
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    onPressed: () => controller.removeRecentSearch(term),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEnhancedNoResultsPrompt(
    BuildContext context, {
    required bool isRentalTab,
  }) {
    final hasSearchText =
        controller.currentSearchQueryForDisplay.value.isNotEmpty;
    final hasFilters = controller.hasActiveFilters;
    String title = "No ${isRentalTab ? 'rentals' : 'items'} found";
    String subtitle = "Try adjusting your search or filters.";
    bool showClearButton = false;
    if (hasSearchText && hasFilters) {
      title =
          'No results for "${controller.currentSearchQueryForDisplay.value}"';
      subtitle = 'Try a different search term or clear your filters.';
      showClearButton = true;
    } else if (hasSearchText) {
      title =
          'No results for "${controller.currentSearchQueryForDisplay.value}"';
      subtitle = 'Check your spelling or try using more general keywords.';
    } else if (hasFilters) {
      title = 'No listings match your filters';
      subtitle = 'Try removing some filters to see more results.';
      showClearButton = true;
    }
    return _buildPromptWidget(
      icon: CupertinoIcons.tray_fill,
      title: title,
      subtitle: subtitle,
      context: context,
      actionButton: showClearButton
          ? ElevatedButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 20),
              label: const Text("Clear All Filters"),
              onPressed: controller.clearAllFiltersAndSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInitialSearchPrompt(BuildContext context) {
    return _buildPromptWidget(
      icon: CupertinoIcons.search_circle_fill,
      title: "Search Campus Marketplace",
      subtitle: "Find items, rentals, and more. Enter a search term to begin.",
      context: context,
    );
  }

  Widget _buildPromptWidget({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? actionButton,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: theme.hintColor.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.hintColor.withValues(alpha: 0.8),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }
}
