import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/user_model.dart' as studora_user;
import 'package:studora/app/data/providers/database_provider.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/network_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';

enum WishlistUiState { loading, hasData, empty, error }

class WishlistController extends GetxController {
  static const String _className = 'WishlistController';
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final DatabaseProvider _databaseProvider = Get.find<DatabaseProvider>();
  final NetworkService _networkService = Get.find<NetworkService>();
  final Rx<WishlistUiState> uiState = WishlistUiState.loading.obs;
  final RxList<ItemModel> wishlistItems = <ItemModel>[].obs;
  final RxSet<String> _wishlistItemIds = <String>{}.obs;
  RxString currentLoggedInUserId = ''.obs;

  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();
  List<ItemModel> displayedItemsForAnimatedList = [];
  Timer? _debounce;
  @override
  void onInit() {
    super.onInit();
    LoggerService.logInfo(
      _className,
      'onInit',
      'WishlistController initialized.',
    );
    _initializeWishlist();
  }

  Future<void> _initializeWishlist() async {
    await _fetchCurrentUserDataAndInitialWishlist();
    if (currentLoggedInUserId.value.isNotEmpty) {
      await fetchWishlistItems();
    } else {
      uiState.value = WishlistUiState.error;
      LoggerService.logWarning(
        _className,
        '_initializeWishlist',
        'User not logged in. Cannot load wishlist.',
      );
    }
  }

  Future<void> _fetchCurrentUserDataAndInitialWishlist() async {
    const String methodName = '_fetchCurrentUserDataAndInitialWishlist';
    try {
      studora_user.UserModel? currentUser = await _authRepository
          .getCurrentAppUser();
      if (currentUser != null) {
        currentLoggedInUserId.value = currentUser.userId;
        _wishlistItemIds.assignAll(currentUser.wishlist?.toSet() ?? {});
        LoggerService.logInfo(
          _className,
          methodName,
          'User ID: ${currentUser.userId}, Wishlist IDs count: ${_wishlistItemIds.length}',
        );
      } else {
        currentLoggedInUserId.value = '';
        _wishlistItemIds.clear();
        LoggerService.logWarning(
          _className,
          methodName,
          'No current user found.',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching user data: $e',
        s,
      );
      currentLoggedInUserId.value = '';
      _wishlistItemIds.clear();
      uiState.value = WishlistUiState.error;
    }
  }

  Future<void> fetchWishlistItems({bool isRefresh = false}) async {
    const String methodName = 'fetchWishlistItems';
    if (!_networkService.isConnected()) {
      uiState.value = WishlistUiState.error;
      SnackbarService.showError(
        "No internet connection. Cannot load wishlist.",
      );
      return;
    }
    if (currentLoggedInUserId.value.isEmpty) {
      LoggerService.logWarning(
        _className,
        methodName,
        'No user logged in, aborting fetch.',
      );
      uiState.value = WishlistUiState.empty;
      return;
    }
    uiState.value = WishlistUiState.loading;
    if (isRefresh) {
      await _fetchCurrentUserDataAndInitialWishlist();
    }
    if (_wishlistItemIds.isEmpty) {
      LoggerService.logInfo(_className, methodName, 'Wishlist is empty.');
      _clearAnimatedList();
      wishlistItems.clear();
      uiState.value = WishlistUiState.empty;
      return;
    }
    try {
      final List<ItemModel> fetchedItems = [];
      for (String itemId in _wishlistItemIds) {
        try {
          final doc = await _databaseProvider.getDocument(
            databaseId: AppConstants.appwriteDatabaseId,
            collectionId: AppConstants.itemsCollectionId,
            documentId: itemId,
          );
          if (doc != null) {
            fetchedItems.add(ItemModel.fromJson(doc.data, doc.$id));
          }
        } catch (e) {
          LoggerService.logWarning(
            _className,
            methodName,
            'Failed to fetch item $itemId: $e',
          );
        }
      }

      fetchedItems.sort((a, b) => b.datePosted.compareTo(a.datePosted));
      _updateAnimatedList(fetchedItems);
      wishlistItems.assignAll(fetchedItems);
      uiState.value = wishlistItems.isEmpty
          ? WishlistUiState.empty
          : WishlistUiState.hasData;
      LoggerService.logInfo(
        _className,
        methodName,
        'Fetched ${wishlistItems.length} items for wishlist.',
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching wishlist items: $e',
        s,
      );
      uiState.value = WishlistUiState.error;
      SnackbarService.showError(
        "Could not load wishlist items. Please try again.",
      );
    }
  }

  void _clearAnimatedList() {
    if (listKey.currentState != null) {
      for (int i = displayedItemsForAnimatedList.length - 1; i >= 0; i--) {
        listKey.currentState!.removeItem(
          i,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: const SizedBox.shrink(),
          ),
          duration: const Duration(milliseconds: 100),
        );
      }
    }
    displayedItemsForAnimatedList.clear();
  }

  void _updateAnimatedList(List<ItemModel> newItems) {
    _clearAnimatedList();
    var future = Future.value();
    for (int i = 0; i < newItems.length; i++) {
      future = future.then((_) {
        return Future.delayed(const Duration(milliseconds: 70), () {
          if (listKey.currentState != null) {
            displayedItemsForAnimatedList.add(newItems[i]);
            listKey.currentState!.insertItem(
              displayedItemsForAnimatedList.length - 1,
              duration: const Duration(milliseconds: 250),
            );
          }
        });
      });
    }
  }

  Future<void> removeFromWishlist(
    ItemModel itemToRemove,
    int indexInAnimatedList,
  ) async {
    const String methodName = 'removeFromWishlist';
    if (currentLoggedInUserId.value.isEmpty) return;
    final originalWishlistItemIds = Set<String>.from(_wishlistItemIds);

    _wishlistItemIds.remove(itemToRemove.id);

    wishlistItems.removeWhere((item) => item.id == itemToRemove.id);
    if (uiState.value == WishlistUiState.hasData && wishlistItems.isEmpty) {
      uiState.value = WishlistUiState.empty;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _authRepository.updateUserWishlist(_wishlistItemIds.toList());
        LoggerService.logInfo(
          _className,
          methodName,
          'Wishlist updated in Appwrite. Item removed: ${itemToRemove.id}',
        );
      } catch (e, s) {
        LoggerService.logError(
          _className,
          methodName,
          'Failed to update Appwrite wishlist for removal: $e',
          s,
        );

        _wishlistItemIds.assignAll(originalWishlistItemIds);

        SnackbarService.showError(
          "Failed to update wishlist. Please try again.",
        );

        fetchWishlistItems();
      }
    });
  }

  Future<void> addItemToWishlist(
    ItemModel itemToAdd,
    int indexInAnimatedList,
  ) async {
    const String methodName = 'addItemToWishlist';
    if (currentLoggedInUserId.value.isEmpty) return;
    final originalWishlistItemIds = Set<String>.from(_wishlistItemIds);

    _wishlistItemIds.add(itemToAdd.id);

    if (!wishlistItems.any((item) => item.id == itemToAdd.id)) {
      wishlistItems.insert(indexInAnimatedList, itemToAdd);
      wishlistItems.sort((a, b) => b.datePosted.compareTo(a.datePosted));
    }
    if (uiState.value == WishlistUiState.empty && wishlistItems.isNotEmpty) {
      uiState.value = WishlistUiState.hasData;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _authRepository.updateUserWishlist(_wishlistItemIds.toList());
        LoggerService.logInfo(
          _className,
          methodName,
          'Wishlist updated in Appwrite. Item added: ${itemToAdd.id}',
        );
      } catch (e, s) {
        LoggerService.logError(
          _className,
          methodName,
          'Failed to update Appwrite wishlist for addition: $e',
          s,
        );

        _wishlistItemIds.assignAll(originalWishlistItemIds);
        SnackbarService.showError(
          "Failed to update wishlist. Please try again.",
        );

        fetchWishlistItems();
      }
    });
  }

  Future<void> handleRefresh() async {
    await fetchWishlistItems(isRefresh: true);
  }

  void navigateToItemDetail(String itemId) {
    Get.toNamed(AppRoutes.ITEM_DETAIL, arguments: itemId);
  }

  void navigateToDiscoverItems() {
    if (Get.currentRoute == AppRoutes.MAIN_NAVIGATION) {
      if (Get.previousRoute.isNotEmpty &&
          Get.previousRoute != Get.currentRoute) {
        Get.back();
      } else {
        Get.offAllNamed(AppRoutes.HOME_DASHBOARD);
      }
    } else {
      Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);
    }
  }

  bool isItemFavorite(String itemId) {
    return _wishlistItemIds.contains(itemId);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
