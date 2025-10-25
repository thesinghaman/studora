import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/models/user_model.dart' as studora_user;
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/services/wishlist_service.dart';

class HomeController extends GetxController {
  static const String _className = 'HomeController';

  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final WishlistService _wishlistService = Get.find<WishlistService>();

  bool get isLoading => !_itemRepository.isInitialized.value;
  var isRefreshing = false.obs;

  var homeScreenCategories = <CategoryModel>[].obs;
  var currentLoggedInUserId = ''.obs;
  var currentUserFirstName = 'there'.obs;

  List<ItemModel> get recentMarketplaceItems {
    return _itemRepository.allMarketplaceItems
        .map((item) {
          return item.copyWith(
            isFavorite: _wishlistService.isFavorite(item.id),
          );
        })
        .take(10)
        .toList();
  }

  final Map<String, IconData> _categoryIconMap = {
    'electronics': CupertinoIcons.device_phone_portrait,
    'books': CupertinoIcons.book_fill,
    'furniture': CupertinoIcons.house_alt_fill,
    'fashion': CupertinoIcons.bag_fill,
    'housing': CupertinoIcons.house_fill,
    'services': CupertinoIcons.wrench_fill,
    'sports': CupertinoIcons.sportscourt_fill,
    'stationery': CupertinoIcons.pencil_outline,
    'other': CupertinoIcons.square_grid_2x2_fill,
    'vehicles': CupertinoIcons.car_detailed,
    'notes_material': CupertinoIcons.doc_text_fill,
  };
  IconData getIconForCategory(String? iconId) {
    return _categoryIconMap[iconId?.toLowerCase()] ??
        CupertinoIcons.square_grid_2x2_fill;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    ever(_itemRepository.isInitialized, (bool isInitialized) {
      if (isInitialized) {
        _loadAuxiliaryData();
      }
    });
  }

  Future<void> _initializeData() async {
    await _itemRepository.initializeAndFetchAllItems();
  }

  Future<void> _loadAuxiliaryData() async {
    await _fetchCurrentUserData();
    await _loadCategories();
  }

  Future<void> _fetchCurrentUserData() async {
    const String methodName = '_fetchCurrentUserData';
    try {
      studora_user.UserModel? currentUser = await _authRepository
          .getCurrentAppUser();
      if (currentUser != null) {
        currentLoggedInUserId.value = currentUser.userId;
        currentUserFirstName.value = currentUser.userName.isNotEmpty
            ? currentUser.userName.split(' ').first
            : 'User';

        _wishlistService.initializeWishlist(currentUser.wishlist ?? []);
      } else {
        _resetUserData();
      }
    } catch (e, s) {
      _resetUserData();
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching user data: $e',
        s,
      );
    }
  }

  Future<void> _loadCategories() async {
    const String methodName = '_loadCategories';
    try {
      final List<CategoryModel> allCategories = await _categoryRepository
          .getCategories();
      homeScreenCategories.assignAll(
        allCategories.where((cat) => cat.type.toLowerCase() == 'sale').toList(),
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error loading categories: $e',
        s,
      );
    }
  }

  void _resetUserData() {
    currentUserFirstName.value = 'Guest';
    currentLoggedInUserId.value = '';

    _wishlistService.clearWishlist();
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    try {
      _itemRepository.isInitialized.value = false;
      await _itemRepository.initializeAndFetchAllItems();
    } finally {
      isRefreshing.value = false;
    }
  }

  void navigateToSearch() => Get.toNamed(AppRoutes.SEARCH);
  void navigateToWishlist() => Get.toNamed(AppRoutes.WISHLIST);
  void navigateToPostAd() => Get.toNamed(AppRoutes.POST_ITEM);
  void navigateToLostAndFound() => Get.toNamed(AppRoutes.LOST_AND_FOUND);
  void navigateToAllRentals() => Get.toNamed(AppRoutes.ALL_ITEMS_RENTALS);
  void navigateToAllMarketplaceItems() =>
      Get.toNamed(AppRoutes.ALL_ITEMS_MARKETPLACE);
  void navigateToCategoryListings(String categoryId, String categoryName) {
    Get.toNamed(
      AppRoutes.CATEGORY_LISTINGS,
      arguments: {'categoryId': categoryId, 'categoryName': categoryName},
    );
  }
}
