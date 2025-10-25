import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/wishlist/controllers/wishlist_controller.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/shared_components/widgets/detailed_list_item_card.dart';
import 'package:studora/app/shared_components/widgets/shimmer_widgets/detailed_list_item_shimmer_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistController controller = Get.find<WishlistController>();
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRemoveFromWishlist(ItemModel itemToRemove) async {
    final int index = controller.displayedItemsForAnimatedList.indexWhere(
      (item) => item.id == itemToRemove.id,
    );
    if (index == -1) return;
    final ItemModel removedItemForBuilder = controller
        .displayedItemsForAnimatedList
        .removeAt(index);
    controller.listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildRemovedItemWidget(removedItemForBuilder, animation),
      duration: const Duration(milliseconds: 300),
    );
    await controller.removeFromWishlist(itemToRemove, index);
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${itemToRemove.title} removed from wishlist"),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        action: SnackBarAction(
          label: "UNDO",
          textColor: Theme.of(context).colorScheme.inversePrimary,
          onPressed: () {
            _handleAddItem(index, removedItemForBuilder);
          },
        ),
      ),
    );
  }

  void _handleAddItem(int index, ItemModel item) async {
    if (index > controller.displayedItemsForAnimatedList.length) {
      controller.displayedItemsForAnimatedList.add(item);
    } else {
      controller.displayedItemsForAnimatedList.insert(index, item);
    }
    controller.listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 250),
    );
    await controller.addItemToWishlist(item, index);
  }

  Widget _buildRemovedItemWidget(
    ItemModel item,
    Animation<double> animation, {
    bool forRefresh = false,
  }) {
    if (forRefresh) {
      return SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.linear),
        child: const SizedBox.shrink(),
      );
    }
    final progressAnimation = CurvedAnimation(
      parent: ReverseAnimation(animation),
      curve: Curves.easeOutSine,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(progressAnimation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(
            parent: progressAnimation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: DetailedListItemCard(
          item: item,
          currentLoggedInUserId: controller.currentLoggedInUserId.value,
          isUserAd: item.sellerId == controller.currentLoggedInUserId.value,
          isFavorite: true,
          onFavoriteTap: () => _handleRemoveFromWishlist(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wishlist"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: controller.handleRefresh,
          color: Theme.of(context).colorScheme.primary,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentStateWidget(context),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStateWidget(BuildContext context) {
    switch (controller.uiState.value) {
      case WishlistUiState.loading:
        return ListView.builder(
          key: const ValueKey('loader_wishlist_shimmer'),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const DetailedListItemShimmerCard();
          },
        );
      case WishlistUiState.error:
        return _buildErrorState(
          context,
          key: const ValueKey('error_state_wishlist'),
        );
      case WishlistUiState.empty:
        return _buildEmptyState(
          context,
          key: const ValueKey('empty_state_wishlist'),
        );
      case WishlistUiState.hasData:
        return _buildWishlistAnimatedList(
          context,
          key: const ValueKey('wishlist_list_content'),
        );
    }
  }

  Widget _buildErrorState(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    "Something Went Wrong",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    "We couldn't load your wishlist. Please check your connection and try again.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: controller.handleRefresh,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      constraints: const BoxConstraints.expand(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.heart_slash_fill,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    "Your Wishlist is Empty",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    "Tap the heart icon on items you like to save them here for later.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.search, size: 18),
                    label: const Text("Discover Items"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: controller.navigateToDiscoverItems,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistAnimatedList(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      child: AnimatedList(
        key: controller.listKey,
        initialItemCount: controller.displayedItemsForAnimatedList.length,
        padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
        itemBuilder: (context, index, animation) {
          if (index >= controller.displayedItemsForAnimatedList.length) {
            return const SizedBox.shrink();
          }
          final item = controller.displayedItemsForAnimatedList[index];
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
            child: SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: DetailedListItemCard(
                item: item,
                currentLoggedInUserId: controller.currentLoggedInUserId.value,
                isUserAd:
                    item.sellerId == controller.currentLoggedInUserId.value,
                isFavorite: true,
                onFavoriteTap: () => _handleRemoveFromWishlist(item),
              ),
            ),
          );
        },
      ),
    );
  }
}
