import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/services/wishlist_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class CategoryListingsController extends GetxController {
  static const String _className = 'CategoryListingsController';

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final WishlistService _wishlistService = Get.find<WishlistService>();

  late final String categoryId;
  late final String categoryName;
  var items = <ItemModel>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasMoreItems = true.obs;
  int _currentPage = 0;
  final int _itemsPerPage = 12;

  var sortBy = SortOption.dateDesc.obs;
  var minPrice = Rx<double?>(null);
  var maxPrice = Rx<double?>(null);

  String? get currentUserId => _authRepository.appUser.value?.userId;
  int get activeFilterCount {
    int count = 0;
    if (minPrice.value != null || maxPrice.value != null) count++;
    if (sortBy.value != SortOption.dateDesc) count++;
    return count;
  }
  @override
  void onInit() {
    super.onInit();

    if (Get.arguments is Map<String, dynamic>) {
      final Map<String, dynamic> args = Get.arguments;
      categoryId = args['categoryId'] ?? '';
      categoryName = args['categoryName'] ?? 'Unknown Category';
    } else {

      categoryId = '';
      categoryName = 'Error';
      LoggerService.logError(
        _className,
        'onInit',
        'Invalid arguments passed to CategoryListingsScreen.',
      );
      Get.back();
      return;
    }
    if (categoryId.isEmpty) {
      isLoading.value = false;
      LoggerService.logError(
        _className,
        'onInit',
        'FATAL: Category ID is empty.',
      );
      return;
    }

    fetchCategoryItems(isNewFetch: true);
  }

  Future<void> handleRefresh() async {
    await fetchCategoryItems(isNewFetch: true);
  }

  Future<void> fetchCategoryItems({bool isNewFetch = false}) async {
    if (isNewFetch) {
      _currentPage = 0;
      hasMoreItems.value = true;
      isLoading.value = true;
      items.clear();
    }
    if (isLoadingMore.value || !hasMoreItems.value) {
      if (isNewFetch) isLoading.value = false;
      return;
    }
    if (!isNewFetch) {
      isLoadingMore.value = true;
    }
    try {
      final currentUserCollegeId = _authRepository.appUser.value?.collegeId;
      final newItems = await _itemRepository.searchItems(
        itemType: 'marketplace',
        collegeId: currentUserCollegeId,
        categoryIds: [categoryId],
        sortBy: sortBy.value.value,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        limit: _itemsPerPage,
        offset: _currentPage * _itemsPerPage,
      );

      final processedItems = newItems
          .map((item) => item.copyWith(isFavorite: isItemFavorite(item.id)))
          .toList();
      if (processedItems.length < _itemsPerPage) {
        hasMoreItems.value = false;
      }
      items.addAll(processedItems);
      _currentPage++;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'fetchCategoryItems',
        'Error fetching items for category $categoryName: $e',
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
    final index = items.indexWhere((i) => i.id == item.id);
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
      items.removeAt(index);
      return;
    }
    if (!updatedItem.isActive) {
      LoggerService.logInfo(
        _className,
        'onItemTap',
        'Item ${item.id} is no longer active (sold/inactive). Removing from list.',
      );
      items.removeAt(index);
      return;
    }
    LoggerService.logInfo(
      _className,
      'onItemTap',
      'Updating item ${item.id} in place.',
    );
    final bool isFavorite = isItemFavorite(updatedItem.id);
    items[index] = updatedItem.copyWith(isFavorite: isFavorite);
  }
  void applyFilters({
    required SortOption newSortBy,
    double? newMinPrice,
    double? newMaxPrice,
  }) {
    sortBy.value = newSortBy;
    minPrice.value = newMinPrice;
    maxPrice.value = newMaxPrice;
    fetchCategoryItems(isNewFetch: true);
  }
  void loadMoreItems() {
    fetchCategoryItems();
  }
  bool isItemFavorite(String itemId) =>
      _wishlistService.favoriteItemIds.contains(itemId);
  void toggleFavorite(String itemId) => _wishlistService.toggleFavorite(itemId);
}
