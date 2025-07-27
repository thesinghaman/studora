import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/modules/main_navigation/controllers/main_navigation_controller.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class MyAdsController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String _className = 'MyAdsController';

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final LostAndFoundRepository _lostAndFoundRepository =
      Get.find<LostAndFoundRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  late TabController tabController;
  var selectedTabIndex = 0.obs;
  var isLoading = true.obs;
  var isExpanded = {
    'listed_active': true.obs,
    'rental_active': true.obs,
    'lf_active': true.obs,
    'listed_inactive': false.obs,
    'listed_expired': false.obs,
    'listed_sold': false.obs,
    'rental_inactive': false.obs,
    'rental_expired': false.obs,
    'rental_rented': false.obs,
    'lf_inactive': false.obs,
    'lf_expired': false.obs,
    'lf_resolved': false.obs,
  }.obs;

  var isSelectionMode = false.obs;
  var selectedItemIds = <String>{}.obs;

  var activeListedAds = <ItemModel>[].obs;
  var inactiveListedAds = <ItemModel>[].obs;
  var expiredListedAds = <ItemModel>[].obs;
  var soldOrRentedListedAds = <ItemModel>[].obs;
  var activeRentalAds = <ItemModel>[].obs;
  var inactiveRentalAds = <ItemModel>[].obs;
  var expiredRentalAds = <ItemModel>[].obs;
  var soldOrRentedRentalAds = <ItemModel>[].obs;
  var activeLostFoundPosts = <LostFoundItemModel>[].obs;
  var inactiveLostFoundPosts = <LostFoundItemModel>[].obs;
  var expiredLostFoundPosts = <LostFoundItemModel>[].obs;
  var resolvedLostFoundPosts = <LostFoundItemModel>[].obs;
  String? get currentUserId => _authRepository.appUser.value?.userId;

  StreamSubscription? _myAdsSubscription;
  StreamSubscription? _mainNavSubscription;
  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabSelection);
    _initialLoad();
    _setupReactiveListeners();
  }

  @override
  void onClose() {
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    _myAdsSubscription?.cancel();
    _mainNavSubscription?.cancel();
    super.onClose();
  }

  void _initialLoad() async {
    isLoading.value = true;
    _processInitialItems(_itemRepository.myAds);
    await _loadLostAndFoundItems();
    isLoading.value = false;
  }

  void _setupReactiveListeners() {
    _myAdsSubscription?.cancel();
    _myAdsSubscription = _itemRepository.myAds.stream.listen(
      _handleItemChanges,
    );
    const myAdsViewIndex = 2;
    _mainNavSubscription?.cancel();
    _mainNavSubscription = Get.find<MainNavigationController>()
        .selectedIndex
        .stream
        .listen((newIndex) {
          if (newIndex == myAdsViewIndex) {
            LoggerService.logInfo(
              _className,
              'Navigation Listener',
              'My Ads tab selected. Re-syncing all data.',
            );
            _handleItemChanges(_itemRepository.myAds);
            _loadLostAndFoundItems();
          } else if (isSelectionMode.value) {
            cancelSelectionMode();
          }
        });
  }

  void _handleTabSelection() {
    if (selectedTabIndex.value != tabController.index) {
      selectedTabIndex.value = tabController.index;
      if (isSelectionMode.value) {
        cancelSelectionMode();
      }
    }
  }

  void _processInitialItems(List<ItemModel> initialItems) {
    _clearItemLists();
    for (final item in initialItems) {
      _categorizeAndAddItem(item);
    }
  }

  void _handleItemChanges(List<ItemModel> updatedListFromRepo) {
    final currentItemsMap = _getCurrentItemsAsMap();
    final updatedItemsMap = {
      for (var item in updatedListFromRepo) item.id: item,
    };
    final deletedIds = currentItemsMap.keys.toSet().difference(
      updatedItemsMap.keys.toSet(),
    );
    for (final itemId in deletedIds) {
      _removeItemFromLocalLists(itemId);
    }
    for (final updatedItem in updatedListFromRepo) {
      final originalItem = currentItemsMap[updatedItem.id];
      if (originalItem == null) {
        _categorizeAndAddItem(updatedItem);
      } else {
        final originalCategory = _getItemCategory(originalItem);
        final newCategory = _getItemCategory(updatedItem);
        if (originalCategory != newCategory) {
          _removeItemFromLocalLists(updatedItem.id);
          _categorizeAndAddItem(updatedItem);
        } else {
          _updateItemInPlace(updatedItem, originalCategory);
        }
      }
    }
  }

  Future<void> _loadLostAndFoundItems() async {
    if (currentUserId == null) return;
    try {
      final lostFoundItems = await _lostAndFoundRepository
          .getAllUserLostAndFoundItems(currentUserId!);
      _clearLostFoundLists();
      for (final item in lostFoundItems) {
        _categorizeAndAddLostFoundItem(item);
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_loadLostAndFoundItems',
        'Error: $e',
        s,
      );
    }
  }

  Future<void> refreshAllData() async {
    await _itemRepository.initializeAndFetchAllItems();
    await _loadLostAndFoundItems();
  }

  Map<String, ItemModel> _getCurrentItemsAsMap() {
    final map = <String, ItemModel>{};
    for (var list in [
      activeListedAds,
      inactiveListedAds,
      expiredListedAds,
      soldOrRentedListedAds,
      activeRentalAds,
      inactiveRentalAds,
      expiredRentalAds,
      soldOrRentedRentalAds,
    ]) {
      for (var item in list) {
        map[item.id] = item;
      }
    }
    return map;
  }

  void _updateItemInPlace(
    ItemModel updatedItem,
    RxList<ItemModel> categoryList,
  ) {
    final index = categoryList.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      if (!identical(categoryList[index], updatedItem)) {
        categoryList[index] = updatedItem;
      }
    }
  }

  void _removeItemFromLocalLists(String itemId) {
    activeListedAds.removeWhere((item) => item.id == itemId);
    inactiveListedAds.removeWhere((item) => item.id == itemId);
    expiredListedAds.removeWhere((item) => item.id == itemId);
    soldOrRentedListedAds.removeWhere((item) => item.id == itemId);
    activeRentalAds.removeWhere((item) => item.id == itemId);
    inactiveRentalAds.removeWhere((item) => item.id == itemId);
    expiredRentalAds.removeWhere((item) => item.id == itemId);
    soldOrRentedRentalAds.removeWhere((item) => item.id == itemId);
  }

  RxList<ItemModel> _getItemCategory(ItemModel item) {
    final isRental = item.isRental;
    final isExpired = item.expiryDate.isBefore(DateTime.now());
    final status = item.adStatus.toLowerCase();
    if (status == 'sold' || status == 'rented') {
      return isRental ? soldOrRentedRentalAds : soldOrRentedListedAds;
    }
    if (status == 'expired' || (item.isActive && isExpired)) {
      return isRental ? expiredRentalAds : expiredListedAds;
    }
    if (!item.isActive || status == 'inactive') {
      return isRental ? inactiveRentalAds : inactiveListedAds;
    }
    return isRental ? activeRentalAds : activeListedAds;
  }

  void _categorizeAndAddItem(ItemModel item) {
    _getItemCategory(item).add(item);
  }

  void _categorizeAndAddLostFoundItem(LostFoundItemModel item) {
    final isExpired = item.expiryDate.isBefore(DateTime.now());
    final status = item.postStatus.toLowerCase();
    if (status == 'resolved' || status == 'claimed') {
      resolvedLostFoundPosts.add(item);
    } else if (status == 'expired' || (item.isActive && isExpired)) {
      expiredLostFoundPosts.add(item);
    } else if (!item.isActive) {
      inactiveLostFoundPosts.add(item);
    } else {
      activeLostFoundPosts.add(item);
    }
    _sortLostFoundList(resolvedLostFoundPosts);
    _sortLostFoundList(expiredLostFoundPosts);
    _sortLostFoundList(inactiveLostFoundPosts);
    _sortLostFoundList(activeLostFoundPosts);
  }

  void _sortLostFoundList(List<LostFoundItemModel> list) =>
      list.sort((a, b) => b.dateReported.compareTo(a.dateReported));
  void _clearItemLists() {
    activeListedAds.clear();
    inactiveListedAds.clear();
    expiredListedAds.clear();
    soldOrRentedListedAds.clear();
    activeRentalAds.clear();
    inactiveRentalAds.clear();
    expiredRentalAds.clear();
    soldOrRentedRentalAds.clear();
  }

  void _clearLostFoundLists() {
    activeLostFoundPosts.clear();
    inactiveLostFoundPosts.clear();
    expiredLostFoundPosts.clear();
    resolvedLostFoundPosts.clear();
  }

  void toggleExpansion(String key) {
    if (isExpanded[key] != null) {
      isExpanded[key]!.value = !isExpanded[key]!.value;
    }
  }

  Future<void> onItemTap(dynamic item) async {
    final String itemId = item is ItemModel
        ? item.id
        : (item as LostFoundItemModel).id!;
    if (isSelectionMode.value) {
      _toggleSelection(itemId);
    } else {
      await _navigateToDetail(item);

      if (item is LostFoundItemModel) {
        LoggerService.logInfo(
          _className,
          'onItemTap',
          'Returned from LostFound detail, refreshing list.',
        );
        await _loadLostAndFoundItems();
      }
    }
  }

  void onItemLongPress(String itemId) {
    isSelectionMode.value = true;
    selectedItemIds.add(itemId);
  }

  void cancelSelectionMode() {
    isSelectionMode.value = false;
    selectedItemIds.clear();
  }

  void _toggleSelection(String itemId) {
    if (selectedItemIds.contains(itemId)) {
      selectedItemIds.remove(itemId);
      if (selectedItemIds.isEmpty) isSelectionMode.value = false;
    } else {
      selectedItemIds.add(itemId);
    }
  }

  Future<void> _navigateToDetail(dynamic item) async {
    if (item is ItemModel) {
      await Get.toNamed(AppRoutes.ITEM_DETAIL, arguments: {'ad': item});
    } else if (item is LostFoundItemModel) {
      await Get.toNamed(AppRoutes.LOST_FOUND_ITEM_DETAIL, arguments: item);
    }
  }

  Set<String> get _expandedItemIdsInCurrentTab {
    final ids = <String>{};
    switch (selectedTabIndex.value) {
      case 0:
        if (isExpanded['listed_active']!.value) {
          ids.addAll(activeListedAds.map((i) => i.id));
        }
        if (isExpanded['listed_inactive']!.value) {
          ids.addAll(inactiveListedAds.map((i) => i.id));
        }
        if (isExpanded['listed_expired']!.value) {
          ids.addAll(expiredListedAds.map((i) => i.id));
        }
        if (isExpanded['listed_sold']!.value) {
          ids.addAll(soldOrRentedListedAds.map((i) => i.id));
        }
        break;
      case 1:
        if (isExpanded['rental_active']!.value) {
          ids.addAll(activeRentalAds.map((i) => i.id));
        }
        if (isExpanded['rental_inactive']!.value) {
          ids.addAll(inactiveRentalAds.map((i) => i.id));
        }
        if (isExpanded['rental_expired']!.value) {
          ids.addAll(expiredRentalAds.map((i) => i.id));
        }
        if (isExpanded['rental_rented']!.value) {
          ids.addAll(soldOrRentedRentalAds.map((i) => i.id));
        }
        break;
      case 2:
        if (isExpanded['lf_active']!.value) {
          ids.addAll(activeLostFoundPosts.map((i) => i.id!));
        }
        if (isExpanded['lf_inactive']!.value) {
          ids.addAll(inactiveLostFoundPosts.map((i) => i.id!));
        }
        if (isExpanded['lf_expired']!.value) {
          ids.addAll(expiredLostFoundPosts.map((i) => i.id!));
        }
        if (isExpanded['lf_resolved']!.value) {
          ids.addAll(resolvedLostFoundPosts.map((i) => i.id!));
        }
        break;
    }
    return ids;
  }

  bool get areAllItemsInCurrentTabSelected =>
      _expandedItemIdsInCurrentTab.isNotEmpty &&
      selectedItemIds.containsAll(_expandedItemIdsInCurrentTab);
  void toggleSelectAllInCurrentTab() {
    final expandedIds = _expandedItemIdsInCurrentTab;
    if (areAllItemsInCurrentTabSelected) {
      selectedItemIds.removeAll(expandedIds);
    } else {
      selectedItemIds.addAll(expandedIds);
    }
  }

  Future<void> deleteSelectedItems() async {
    final idsToDelete = Set<String>.from(selectedItemIds);
    if (idsToDelete.isEmpty) {
      cancelSelectionMode();
      return;
    }
    final currentTab = selectedTabIndex.value;
    final deleteFutures = <Future>[];
    try {
      isLoading.value = true;
      if (currentTab == 0 || currentTab == 1) {
        final itemsToDelete = _itemRepository.myAds
            .where((item) => idsToDelete.contains(item.id))
            .toList();
        for (final item in itemsToDelete) {
          deleteFutures.add(
            _itemRepository.deleteItem(
              item.id,
              item.imageFileIds,
              AppConstants.itemsImagesBucketId,
            ),
          );
        }
      } else {
        final allItems = [
          ...activeLostFoundPosts,
          ...inactiveLostFoundPosts,
          ...expiredLostFoundPosts,
          ...resolvedLostFoundPosts,
        ];
        final itemsToDelete = allItems
            .where((item) => idsToDelete.contains(item.id!))
            .toList();
        for (final item in itemsToDelete) {
          deleteFutures.add(
            _lostAndFoundRepository.deleteLostFoundItemWithImages(
              item.id!,
              item.imageUrls,
            ),
          );
        }
      }
      await Future.wait(deleteFutures);
      if (currentTab == 2) await _loadLostAndFoundItems();
      SnackbarService.showSuccess('${idsToDelete.length} item(s) deleted.');
    } catch (e, s) {
      LoggerService.logError(_className, 'deleteSelectedItems', 'Error: $e', s);
      SnackbarService.showError('Failed to delete items.');
    } finally {
      isLoading.value = false;
      cancelSelectionMode();
    }
  }

  IconData? getCategoryIconById(String categoryId) {
    const categoryIcons = {
      'electronics': CupertinoIcons.device_phone_portrait,
      'books': CupertinoIcons.book_fill,
      'notes_assignments': CupertinoIcons.doc_text_fill,
      'stationery': CupertinoIcons.pencil_outline,
      'lab_equipment': CupertinoIcons.lab_flask_solid,
      'other': CupertinoIcons.square_grid_2x2_fill,
    };
    return categoryIcons[categoryId];
  }
}
