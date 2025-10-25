import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/storage_service.dart';
import 'package:studora/app/services/wishlist_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';

class ASearchController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String _className = 'ASearchController';

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final WishlistService _wishlistService = Get.find<WishlistService>();
  final StorageService _storageService = Get.find<StorageService>();

  late TextEditingController searchTextController;
  late FocusNode searchFocusNode;
  late TabController tabController;
  Timer? _debounce;

  var isLoadingInitialData = true.obs;
  var isPerformingSearch = false.obs;
  var isLoadingMore = false.obs;
  var isDebouncing = false.obs;
  var hasPerformedSearchWithText = false.obs;
  var currentSearchQueryForDisplay = "".obs;
  var marketplaceDisplayResults = <ItemModel>[].obs;
  var rentalDisplayResults = <ItemModel>[].obs;
  var recentSearches = <String>[].obs;
  final int _maxRecentSearches = 10;

  var selectedItemTypeTabIndex = 0.obs;
  var selectedCategoryIds = <String>{}.obs;
  var sortBy = SortOption.dateDesc.obs;
  var minPrice = Rx<double?>(null);
  var maxPrice = Rx<double?>(null);
  final RxList<CategoryModel> _appSaleCategories = <CategoryModel>[].obs;
  final RxList<CategoryModel> _appRentalCategories = <CategoryModel>[].obs;
  var currentCategoriesForFilterModal = <CategoryModel>[].obs;

  var currentPage = 0.obs;
  var hasMoreItems = true.obs;
  final int _itemsPerPage = 10;

  String? get currentUserId => _authRepository.appUser.value?.userId;
  bool get hasActiveFilters =>
      selectedCategoryIds.isNotEmpty ||
      minPrice.value != null ||
      maxPrice.value != null ||
      sortBy.value != SortOption.dateDesc;
  bool get showTabsAndResultsHeader =>
      hasPerformedSearchWithText.value || hasActiveFilters;
  int get activeFilterCount {
    int count = 0;
    if (selectedCategoryIds.isNotEmpty) count++;
    if (minPrice.value != null || maxPrice.value != null) count++;
    if (sortBy.value != SortOption.dateDesc) count++;
    return count;
  }

  @override
  void onInit() {
    super.onInit();

    LoggerService.logInfo(
      _className,
      'onInit',
      'ASearchController Initialized (Instance: $hashCode)',
    );
    searchTextController = TextEditingController();
    searchTextController.addListener(_onSearchQueryChanged);
    searchFocusNode = FocusNode();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabSelection);
    _fetchCategoryData();
    _loadRecentSearches();
  }

  @override
  void onClose() {
    LoggerService.logInfo(
      _className,
      'onClose',
      'ASearchController Closed (Instance: $hashCode)',
    );
    searchTextController.removeListener(_onSearchQueryChanged);
    searchTextController.dispose();
    searchFocusNode.dispose();
    tabController.removeListener(_handleTabSelection);
    tabController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  void _onSearchQueryChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    isDebouncing.value = true;
    _debounce = Timer(const Duration(milliseconds: 600), () {
      isDebouncing.value = false;
      performSearch(isNewSearch: true);
    });
  }

  void onSearchSubmitted(String querySubmitted) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    isDebouncing.value = false;
    performSearch(queryOverride: querySubmitted, isNewSearch: true);
    searchFocusNode.unfocus();
  }

  void performSearch({String? queryOverride, bool isNewSearch = false}) async {
    final String currentQuery = (queryOverride ?? searchTextController.text)
        .trim();
    if (isNewSearch && currentQuery.isNotEmpty) {
      _addSearchTerm(currentQuery);
    }
    if (currentQuery.isEmpty && !hasActiveFilters) {
      _clearAllSearchResultsAndFlags();
      return;
    }
    if (isNewSearch) {
      currentPage.value = 0;
      hasMoreItems.value = true;
      isPerformingSearch.value = true;
      marketplaceDisplayResults.clear();
      rentalDisplayResults.clear();
    } else {
      if (isLoadingMore.value || !hasMoreItems.value) return;
      isLoadingMore.value = true;
    }
    currentSearchQueryForDisplay.value = currentQuery;
    hasPerformedSearchWithText.value = true;
    try {
      final String? currentUserCollegeId =
          _authRepository.appUser.value?.collegeId;
      final results = await _itemRepository.searchItems(
        itemType: selectedItemTypeTabIndex.value == 0
            ? 'marketplace'
            : 'rental',
        searchQuery: currentQuery.isNotEmpty ? currentQuery : null,
        categoryIds: selectedCategoryIds.isNotEmpty
            ? selectedCategoryIds.toList()
            : null,
        collegeId: currentUserCollegeId,
        limit: _itemsPerPage,
        offset: currentPage.value * _itemsPerPage,
        sortBy: sortBy.value.value,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
      );
      final processedResults = results
          .map((item) => item.copyWith(isFavorite: isItemFavorite(item.id)))
          .toList();
      if (processedResults.length < _itemsPerPage) {
        hasMoreItems.value = false;
      }
      if (selectedItemTypeTabIndex.value == 0) {
        marketplaceDisplayResults.addAll(processedResults);
      } else {
        rentalDisplayResults.addAll(processedResults);
      }
    } catch (e, s) {
      LoggerService.logError(_className, 'performSearch', 'Error: $e', s);
      SnackbarService.showError("An error occurred during search.");
    } finally {
      isPerformingSearch.value = false;
      isLoadingMore.value = false;
    }
  }

  void loadMoreResults() {
    if (!isLoadingMore.value &&
        hasMoreItems.value &&
        !isPerformingSearch.value) {
      currentPage.value++;
      performSearch(isNewSearch: false);
    }
  }

  void _handleTabSelection() {
    if (!tabController.indexIsChanging &&
        selectedItemTypeTabIndex.value != tabController.index) {
      selectedItemTypeTabIndex.value = tabController.index;
      _updateCurrentCategoriesForFilterModal();
      if (searchTextController.text.trim().isNotEmpty || hasActiveFilters) {
        performSearch(isNewSearch: true);
      }
    }
  }

  void onItemTap(ItemModel item) async {
    final listToUpdate = selectedItemTypeTabIndex.value == 0
        ? marketplaceDisplayResults
        : rentalDisplayResults;

    await Get.toNamed(AppRoutes.ITEM_DETAIL, arguments: {'ad': item});

    final ItemModel? updatedItem = await _itemRepository.getItemById(item.id);

    final index = listToUpdate.indexWhere((i) => i.id == item.id);

    if (index == -1) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} no longer in the search results.',
      );
      return;
    }

    if (updatedItem == null) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} was deleted. Removing from search results.',
      );
      listToUpdate.removeAt(index);
      return;
    }

    if (!updatedItem.isActive) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} is no longer active. Removing from search results.',
      );
      listToUpdate.removeAt(index);
      return;
    }

    LoggerService.logInfo(
      _className,
      'onItemTap',
      'Updating item ${item.id} in search results.',
    );
    final bool isFavorite = isItemFavorite(updatedItem.id);

    listToUpdate[index] = updatedItem.copyWith(isFavorite: isFavorite);
  }

  Future<void> _fetchCategoryData() async {
    isLoadingInitialData.value = true;
    try {
      List<CategoryModel> allCats = await _categoryRepository.getCategories();
      _appSaleCategories.assignAll(
        allCats.where((c) => c.type.toLowerCase() == 'sale').toList(),
      );
      _appRentalCategories.assignAll(
        allCats
            .where(
              (c) =>
                  c.type.toLowerCase() == 'rental' ||
                  c.type.toLowerCase() == 'housing',
            )
            .toList(),
      );
      _updateCurrentCategoriesForFilterModal();
    } catch (e, s) {
      LoggerService.logError(_className, '_fetchCategoryData', 'Error: $e', s);
    } finally {
      isLoadingInitialData.value = false;
    }
  }

  void _loadRecentSearches() {
    recentSearches.assignAll(_storageService.getRecentSearches());
  }

  void _updateCurrentCategoriesForFilterModal() {
    currentCategoriesForFilterModal.assignAll(
      selectedItemTypeTabIndex.value == 0
          ? _appSaleCategories
          : _appRentalCategories,
    );
  }

  Future<void> _addSearchTerm(String term) async {
    final cleanedTerm = term.trim().toLowerCase();
    if (cleanedTerm.isEmpty) return;
    recentSearches.remove(cleanedTerm);
    recentSearches.insert(0, cleanedTerm);
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
    }
    await _storageService.saveRecentSearches(recentSearches.toList());
  }

  Future<void> removeRecentSearch(String term) async {
    recentSearches.remove(term.toLowerCase());
    await _storageService.saveRecentSearches(recentSearches.toList());
  }

  Future<void> clearAllRecentSearches() async {
    recentSearches.clear();
    await _storageService.saveRecentSearches([]);
  }

  void applyFiltersAndSearch({
    required SortOption newSortBy,
    required Set<String> newCategoryIds,
    double? newMinPrice,
    double? newMaxPrice,
  }) {
    sortBy.value = newSortBy;
    selectedCategoryIds.assignAll(newCategoryIds);
    minPrice.value = newMinPrice;
    maxPrice.value = newMaxPrice;
    performSearch(isNewSearch: true);
  }

  void clearAllFiltersAndSearch() {
    applyFiltersAndSearch(
      newSortBy: SortOption.dateDesc,
      newCategoryIds: {},
      newMinPrice: null,
      newMaxPrice: null,
    );
    searchTextController.clear();
  }

  void clearSearchTextAndResubmit() {
    searchTextController.clear();
    searchFocusNode.unfocus();
  }

  void _clearAllSearchResultsAndFlags() {
    marketplaceDisplayResults.clear();
    rentalDisplayResults.clear();
    hasPerformedSearchWithText.value = false;
    currentSearchQueryForDisplay.value = "";
  }

  bool isItemFavorite(String itemId) =>
      _wishlistService.favoriteItemIds.contains(itemId);
  void toggleFavorite(String itemId) => _wishlistService.toggleFavorite(itemId);
}
