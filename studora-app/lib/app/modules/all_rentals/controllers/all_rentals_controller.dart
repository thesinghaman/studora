import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/wishlist_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class AllRentalsController extends GetxController {
  static const String _className = 'AllRentalsController';

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final WishlistService _wishlistService = Get.find<WishlistService>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  var rentalItems = <ItemModel>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasMoreItems = true.obs;
  int _currentPage = 0;
  final int _itemsPerPage = 12;

  var rentalCategories = <CategoryModel>[].obs;
  var selectedCategoryIds = <String>{}.obs;
  var sortBy = SortOption.dateDesc.obs;
  var minPrice = Rx<double?>(null);
  var maxPrice = Rx<double?>(null);

  RxSet<String> get favoriteItemIds => _wishlistService.favoriteItemIds;
  String? get currentLoggedInUserId => _authRepository.appUser.value?.userId;
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
    _initializePage();
  }
  Future<void> _initializePage() async {
    await _fetchRentalCategories();
    await fetchRentalItems(isNewFetch: true);
  }
  Future<void> _fetchRentalCategories() async {
    try {
      final allCats = await _categoryRepository.getCategories();
      rentalCategories.assignAll(
        allCats
            .where(
              (c) =>
                  c.type.toLowerCase() == 'rental' ||
                  c.type.toLowerCase() == 'housing',
            )
            .toList(),
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_fetchRentalCategories',
        'Error fetching categories: $e',
        s,
      );
    }
  }
  Future<void> fetchRentalItems({bool isNewFetch = false}) async {
    if (isNewFetch) {
      _currentPage = 0;
      hasMoreItems.value = true;
      isLoading.value = true;
      rentalItems.clear();
    }
    if (isLoadingMore.value || !hasMoreItems.value) {
      if (isNewFetch) isLoading.value = false;
      return;
    }
    if (!isNewFetch) {
      isLoadingMore.value = true;
    }
    try {
      final String? currentUserCollegeId =
          _authRepository.appUser.value?.collegeId;
      final newItems = await _itemRepository.searchItems(
        itemType: 'rental',
        searchQuery: null,
        collegeId: currentUserCollegeId,
        categoryIds: selectedCategoryIds.isEmpty
            ? null
            : selectedCategoryIds.toList(),
        sortBy: sortBy.value.value,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );
      if (newItems.length < _itemsPerPage) {
        hasMoreItems.value = false;
      }
      rentalItems.addAll(
        newItems.map(
          (item) => item.copyWith(isFavorite: isItemFavorite(item.id)),
        ),
      );
      _currentPage++;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'fetchRentalItems',
        'Error fetching rental items: $e',
        s,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  void onItemTap(ItemModel item) async {

    await Get.toNamed(AppRoutes.ITEM_DETAIL, arguments: {'ad': item});

    final ItemModel? updatedItem = await _itemRepository.getItemById(item.id);

    final index = rentalItems.indexWhere((i) => i.id == item.id);

    if (index == -1) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Returned from detail screen. Item ${item.id} no longer in the list.',
      );
      return;
    }

    if (updatedItem == null) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} was deleted. Removing from list.',
      );
      rentalItems.removeAt(index);
      return;
    }

    if (!updatedItem.isActive) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} is no longer active (sold/inactive). Removing from list.',
      );
      rentalItems.removeAt(index);
      return;
    }

    LoggerService.logInfo(
      _className,
      'onItemTap',
      'Updating item ${item.id} in place.',
    );
    final bool isFavorite = isItemFavorite(updatedItem.id);

    rentalItems[index] = updatedItem.copyWith(isFavorite: isFavorite);
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
    fetchRentalItems(isNewFetch: true);
  }
  Future<void> handleRefresh() async {
    await fetchRentalItems(isNewFetch: true);
  }
  void loadMoreItems() {
    fetchRentalItems();
  }
  bool isItemFavorite(String itemId) =>
      _wishlistService.favoriteItemIds.contains(itemId);
  void toggleFavoriteRental(String itemId) =>
      _wishlistService.toggleFavorite(itemId);
}
