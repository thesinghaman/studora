import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/report_repository.dart';
import 'package:studora/app/services/wishlist_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class AdDetailController extends GetxController {
  static const String _className = 'AdDetailController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final ReportRepository _reportRepository = Get.find<ReportRepository>();
  final WishlistService _wishlistService = Get.find<WishlistService>();

  final Rx<ItemModel?> rxAd = Rxn<ItemModel>();
  final isLoading = true.obs;
  final isUpdatingAd = false.obs;
  final isLoadingChatInitiation = false.obs;
  final isCheckingReportStatus = false.obs;
  final rxCategoryName = 'Loading...'.obs;
  final _currentImageIndex = 0.obs;

  String? get currentUserId => _authRepository.appUser.value?.userId;
  bool get isOwner => rxAd.value?.sellerId == currentUserId;
  bool get isFavorite =>
      _wishlistService.favoriteItemIds.contains(rxAd.value?.id);
  int get currentImageIndex => _currentImageIndex.value;
  set currentImageIndex(int value) => _currentImageIndex.value = value;
  String get adStatus => rxAd.value?.adStatus ?? "N/A";
  String get currencySymbol => _authRepository.currencySymbol;

  final PageController imagePageController = PageController();
  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments == null ||
        arguments['ad'] == null ||
        arguments['ad'] is! ItemModel) {
      _handleInitializationError("Invalid or missing 'ad' argument.");
      return;
    }
    final initialAd = arguments['ad'] as ItemModel;
    rxAd.value = initialAd;
    _loadAuxiliaryAdDetails();
    _setupAdListener(initialAd.id);
  }

  void _setupAdListener(String adId) {

    ever<List<ItemModel>>(_itemRepository.allMarketplaceItems, (list) {
      if (rxAd.value?.isRental == false) {
        _handleRepositoryUpdate(list, adId, 'Marketplace');
      }
    });

    ever<List<ItemModel>>(_itemRepository.allRentalItems, (list) {
      if (rxAd.value?.isRental == true) {
        _handleRepositoryUpdate(list, adId, 'Rental');
      }
    });

    if (isOwner) {
      ever<List<ItemModel>>(_itemRepository.myAds, (list) {
        final myAdVersion = list.firstWhereOrNull((item) => item.id == adId);
        if (myAdVersion != null && myAdVersion != rxAd.value) {
          LoggerService.logInfo(
            _className,
            '_setupAdListener (MyAds)',
            'Ad $adId was updated in myAds list. Syncing UI.',
          );
          rxAd.value = myAdVersion;
        }
      });
    }
  }
  void _handleRepositoryUpdate(
    List<ItemModel> list,
    String adId,
    String sourceType,
  ) {

    if (Get.currentRoute != AppRoutes.ITEM_DETAIL) return;
    final updatedItem = list.firstWhereOrNull((item) => item.id == adId);
    if (updatedItem != null) {

      if (updatedItem != rxAd.value) {
        LoggerService.logInfo(
          _className,
          '_handleRepositoryUpdate ($sourceType)',
          'Ad $adId data was updated from repository stream.',
        );
        rxAd.value = updatedItem;
        _fetchCategoryDetails();
      }
    } else {




      if (!isOwner) {
        LoggerService.logInfo(
          _className,
          '_handleRepositoryUpdate ($sourceType)',
          'Ad $adId was removed from public view. Closing detail screen for non-owner.',
        );
        if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
        Get.back();
        SnackbarService.showInfo("This ad is no longer available.");
      }


    }
  }
  void _handleInitializationError(String message) {
    LoggerService.logError(_className, "onInit", message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SnackbarService.showError("Could not load ad details.");
      if (Get.key.currentState?.canPop() == true) Get.back();
    });
    isLoading.value = false;
  }
  Future<void> _loadAuxiliaryAdDetails() async {
    isLoading.value = true;
    try {
      await _fetchCategoryDetails();
    } catch (e, s) {
      LoggerService.logError(
        _className,
        "_loadAuxiliaryAdDetails",
        "Error: $e",
        s,
      );
      SnackbarService.showError("Error displaying ad details.");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> _fetchCategoryDetails() async {
    final categoryId = rxAd.value?.categoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      try {
        final category = await _categoryRepository.getCategoryById(categoryId);
        rxCategoryName.value = category?.name ?? categoryId;
      } catch (e) {
        rxCategoryName.value = categoryId;
      }
    } else {
      rxCategoryName.value = 'N/A';
    }
  }
  String itemConditionToString(ItemCondition? condition) {
    if (condition == null || condition == ItemCondition.notApplicable) {
      return 'N/A';
    }
    switch (condition) {
      case ItemCondition.aNew:
        return "New";
      case ItemCondition.likeNew:
        return "Used - Like New";
      case ItemCondition.excellent:
        return "Used - Excellent";
      case ItemCondition.good:
        return "Used - Good";
      case ItemCondition.fair:
        return "Used - Fair";
      default:
        return "Unknown";
    }
  }
  void toggleFavorite() {
    if (rxAd.value == null) return;
    _wishlistService.toggleFavorite(rxAd.value!.id);
  }

  Future<void> _updateAd(ItemModel updatedItemData) async {
    isUpdatingAd.value = true;
    try {
      await _itemRepository.updateItem(
        updatedItemData: updatedItemData,
        bucketId: AppConstants.itemsImagesBucketId,
      );
      if (Get.isBottomSheetOpen ?? false) Get.back();
      SnackbarService.showSuccess("Ad status updated successfully.");
    } catch (e, s) {
      LoggerService.logError(_className, '_updateAd', 'Error: $e', s);
      SnackbarService.showError("Failed to update ad: ${e.toString()}");
    } finally {
      isUpdatingAd.value = false;
    }
  }
  void makeAdActiveAgain({bool forceExtendExpiry = false}) {
    final ad = rxAd.value;
    if (ad == null) return;
    DateTime newExpiry;
    final isExpired = ad.expiryDate.isBefore(DateTime.now());
    if (forceExtendExpiry || isExpired) {
      newExpiry = DateTime.now().add(const Duration(days: 30));
    } else {
      newExpiry = ad.expiryDate;
    }
    _updateAd(
      ad.copyWith(isActive: true, adStatus: "Active", expiryDate: newExpiry),
    );
  }
  void makeAdInactive() {
    if (rxAd.value == null) return;
    _updateAd(rxAd.value!.copyWith(isActive: false, adStatus: "Inactive"));
  }
  void markAsSoldOrRented() {
    if (rxAd.value == null) return;
    final newStatus = rxAd.value!.isRental ? "Rented" : "Sold";
    _updateAd(rxAd.value!.copyWith(isActive: false, adStatus: newStatus));
  }
  void confirmDeleteAd() async {
    final ad = rxAd.value;
    if (ad == null) return;
    isUpdatingAd.value = true;
    try {
      await _itemRepository.deleteItem(
        ad.id,
        ad.imageFileIds,
        AppConstants.itemsImagesBucketId,
      );


      if (Get.currentRoute == AppRoutes.ITEM_DETAIL) {
        Get.back(result: {'deleted': true, 'adId': ad.id});
        SnackbarService.showSuccess("Ad has been deleted.");
      }
    } catch (e) {
      SnackbarService.showError("Failed to delete ad: ${e.toString()}");
    } finally {
      isUpdatingAd.value = false;
    }
  }
  void editAd() {
    if (rxAd.value == null) return;
    Get.toNamed(AppRoutes.EDIT_ITEM, arguments: rxAd.value)?.then((result) {
      if (result is ItemModel) {


        SnackbarService.showSuccess(
          "${result.title} has been successfully updated.",
          title: "Ad Updated!",
        );
      }
    });
  }
  Future<void> initiateChat() async {
    final ad = rxAd.value;
    final currentUser = _authRepository.appUser.value;
    if (ad == null || currentUser == null) return;
    if (isOwner) {
      SnackbarService.showInfo("This is your own listing.");
      return;
    }
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments?['openedFromChatFlow'] as bool? ?? false) {
      Get.back();
      return;
    }
    isLoadingChatInitiation.value = true;
    try {
      final convo = await _chatRepository.findExistingConversation(
        currentUser.userId,
        ad.sellerId,
      );

      final relatedItemToSend = RelatedItem(
        itemId: ad.id,
        itemType: 'ItemModel',
        ownerId: ad.sellerId,
        title: ad.title,
        imageUrl: ad.imageUrls?.isNotEmpty == true ? ad.imageUrls!.first : null,
        createdAt: DateTime.now(),
      );
      if (convo != null) {

        Get.toNamed(
          AppRoutes.INDIVIDUAL_CHAT,
          arguments: {'conversation': convo, 'relatedItem': relatedItemToSend},
        );
      } else {

        Get.toNamed(
          AppRoutes.INDIVIDUAL_CHAT,
          arguments: {
            'otherUserId': ad.sellerId,
            'otherUserName': ad.sellerName,
            'otherUserAvatarUrl': ad.sellerProfilePicUrl,
            'relatedItem': relatedItemToSend,
          },
        );
      }
    } catch (e) {
      LoggerService.logError(_className, 'initiateChat', e);
      SnackbarService.showError("Could not start chat. Please try again.");
    } finally {
      isLoadingChatInitiation.value = false;
    }
  }
  void navigateToReportAd() async {
    if (rxAd.value == null || currentUserId == null) return;
    isCheckingReportStatus.value = true;
    try {
      final existingReport = await _reportRepository.findExistingPendingReport(
        reporterId: currentUserId!,
        reportedId: rxAd.value!.id,
        type: ReportType.item,
      );
      if (existingReport != null) {
        Get.toNamed(
          AppRoutes.EXISTING_REPORT_DETAIL,
          arguments: {'report': existingReport},
        );
      } else {
        Get.toNamed(
          AppRoutes.REPORT_SUBMISSION,
          arguments: {
            'reportedItemId': rxAd.value!.id,
            'reportedItemTitle': rxAd.value!.title,
            'reportType': ReportType.item,
          },
        );
      }
    } catch (e) {
      LoggerService.logError(_className, 'navigateToReportAd', 'Error: $e');
      SnackbarService.showError("Could not check report status.");
    } finally {
      isCheckingReportStatus.value = false;
    }
  }
  @override
  void onClose() {
    imagePageController.dispose();
    super.onClose();
  }
}
