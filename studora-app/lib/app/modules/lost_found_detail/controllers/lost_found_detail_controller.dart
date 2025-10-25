import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/related_item_model.dart';
import 'package:studora/app/data/models/user_model.dart' as studora_user;
import 'package:studora/app/data/models/category_model.dart'
    as app_category_model;
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';

class LostFoundDetailController extends GetxController {
  static const String _className = 'LostFoundDetailController';

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final LostAndFoundRepository _lfRepository =
      Get.find<LostAndFoundRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();

  late LostFoundItemModel _initialItemModel;

  Rx<LostFoundItemModel> rxItemModel = LostFoundItemModel(
    id: '',
    title: '',
    description: '',
    location: '',
    dateReported: DateTime.now(),
    type: LostFoundType.lost,
    categoryId: '',
    reporterId: '',
    reporterName: '',
    expiryDate: DateTime.now(),
  ).obs;
  var isLoading = true.obs;
  var isOwner = false.obs;
  var categoryName = 'Loading...'.obs;
  var isProcessingAction = false.obs;
  var isLoadingChatInitiation = false.obs;

  late PageController imagePageController;
  var currentImageIndex = 0.obs;
  bool _openedFromChatFlow = false;
  // ignore: unused_field
  String? _originatingConversationId;

  var showFab = false.obs;
  var primaryActionText = "".obs;
  var primaryActionIcon = Rx<IconData>(CupertinoIcons.chat_bubble_2_fill);
  @override
  void onInit() {
    super.onInit();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    isLoading.value = true;
    final arguments = Get.arguments;

    if (arguments is Map<String, dynamic> &&
        arguments['post'] is LostFoundItemModel) {
      _initialItemModel = arguments['post'] as LostFoundItemModel;
      rxItemModel.value = _initialItemModel.copyWith();
      _openedFromChatFlow = arguments['openedFromChatFlow'] as bool? ?? false;
      _originatingConversationId =
          arguments['originatingConversationId'] as String?;
    } else if (arguments is LostFoundItemModel) {
      _initialItemModel = arguments;
      rxItemModel.value = _initialItemModel.copyWith();
    } else {
      LoggerService.logError(
        _className,
        "onInit",
        "Invalid or missing 'LostFoundItemModel' argument.",
      );
      SnackbarService.showError(
        "Could not load item details. Information missing.",
      );

      if (Get.previousRoute.isNotEmpty &&
          Get.key.currentState?.canPop() == true) {
        Get.back();
      }
      isLoading.value = false;
      return;
    }
    imagePageController = PageController(initialPage: 0);
    final studora_user.UserModel? currentUser = _authRepository.appUser.value;
    isOwner.value = _initialItemModel.reporterId == currentUser?.userId;
    await _fetchCategoryDetails();
    _updateFabState();
    isLoading.value = false;
  }

  void _updateFabState() {
    final item = rxItemModel.value;
    bool isDisplayExpired = item.expiryDate.isBefore(DateTime.now());
    bool isFinallyResolved =
        item.postStatus == "Reunited" || item.postStatus == "Returned";
    showFab.value =
        !isOwner.value &&
        item.isActive &&
        !isDisplayExpired &&
        !isFinallyResolved;
    primaryActionText.value = item.type == LostFoundType.lost
        ? "Found This? Contact Poster"
        : "Is This Yours? Contact Finder";
  }

  Future<void> _fetchCategoryDetails() async {
    if (rxItemModel.value.categoryId.isNotEmpty) {
      try {
        final app_category_model.CategoryModel? category =
            await _categoryRepository.getCategoryById(
              rxItemModel.value.categoryId,
            );
        categoryName.value = category?.name ?? "Unknown Category";
      } catch (e) {
        LoggerService.logError(
          _className,
          '_fetchCategoryDetails',
          'Error fetching category: $e',
        );
        categoryName.value = "Unknown";
      }
    } else {
      categoryName.value = "N/A";
    }
  }

  void _updateLocalReactiveStates(LostFoundItemModel updatedItemFromServer) {
    rxItemModel.value = updatedItemFromServer;
    _updateFabState();
  }

  String determineDisplayStatus() {
    final item = rxItemModel.value;
    if (item.postStatus == "Reunited" || item.postStatus == "Returned") {
      return item.postStatus;
    }
    if (item.postStatus == "Deleted") {
      return "Deleted";
    }
    if (!item.isActive) return "Inactive";
    if (item.expiryDate.isBefore(DateTime.now())) {
      return "Expired";
    }
    return "Active";
  }

  Future<void> _notifyLostAndFoundListController(
    LostFoundItemModel item, {
    bool wasDeleted = false,
  }) async {}

  Future<void> _updatePostStatusAndNotify({
    required bool newActiveState,
    DateTime? newExpiryDate,
    required String newPostStatus,
    bool shouldCloseDetailScreenAfterUpdate = false,
  }) async {
    if (rxItemModel.value.id == null) {
      SnackbarService.showError("Item ID is missing, cannot update status.");
      return;
    }
    isProcessingAction.value = true;
    try {
      LostFoundItemModel itemToUpdateForBackend = rxItemModel.value.copyWith(
        isActive: newActiveState,
        postStatus: newPostStatus,
        expiryDate: newExpiryDate ?? rxItemModel.value.expiryDate,
      );
      final updatedItemFromServer = await _lfRepository.updateLostFoundItem(
        rxItemModel.value.id!,
        itemToUpdateForBackend.toJson(),
      );
      _updateLocalReactiveStates(updatedItemFromServer);
      await _notifyLostAndFoundListController(updatedItemFromServer);
      SnackbarService.showSuccess("Post status updated to '$newPostStatus'.");

      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
      if (shouldCloseDetailScreenAfterUpdate) {
        Get.back(result: 'item_status_updated');
      }
    } catch (e) {
      LoggerService.logError(
        _className,
        '_updatePostStatusAndNotify',
        'Error: $e',
      );
      SnackbarService.showError(
        "Failed to update post status: ${e.toString()}",
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  void makePostActiveAgain({bool forceExtendExpiry = false}) {
    DateTime newExpiryToSet;
    bool isCurrentlyExpiredByDate = rxItemModel.value.expiryDate.isBefore(
      DateTime.now(),
    );
    if (forceExtendExpiry || isCurrentlyExpiredByDate) {
      newExpiryToSet = DateTime.now().add(const Duration(days: 15));
    } else {
      newExpiryToSet = rxItemModel.value.expiryDate;
    }
    _updatePostStatusAndNotify(
      newActiveState: true,
      newExpiryDate: newExpiryToSet,
      newPostStatus: "Active",
    );
  }

  void makePostInactive() {
    _updatePostStatusAndNotify(
      newActiveState: false,
      newPostStatus: "Inactive",
    );
  }

  void markAsResolved() {
    String resolvedStatus = rxItemModel.value.type == LostFoundType.lost
        ? "Reunited"
        : "Returned";

    _updatePostStatusAndNotify(
      newActiveState: false,
      newPostStatus: resolvedStatus,
      shouldCloseDetailScreenAfterUpdate: true,
    );
  }

  void editPost() {
    if (rxItemModel.value.id == null) {
      SnackbarService.showError("Cannot edit: Item data is missing.");
      return;
    }
    Get.toNamed(
      AppRoutes.EDIT_LOST_FOUND_ITEM,
      arguments: rxItemModel.value,
    )?.then((result) {
      if (result is LostFoundItemModel) {
        _updateLocalReactiveStates(result);

        _notifyLostAndFoundListController(result);

        SnackbarService.showSuccess("Post updated successfully.");
      } else if (result == true) {
        _fetchItemDetailsFromServerAfterEdit();
      }
    });
  }

  Future<void> _fetchItemDetailsFromServerAfterEdit() async {
    if (_initialItemModel.id == null) return;
    isProcessingAction.value = true;
    try {
      final fetchedItem = await _lfRepository.getLostFoundItemById(
        _initialItemModel.id!,
      );
      _updateLocalReactiveStates(fetchedItem);
      await _fetchCategoryDetails();
      await _notifyLostAndFoundListController(fetchedItem);
      SnackbarService.showInfo("Details refreshed after edit.");
    } catch (e) {
      SnackbarService.showError(
        "Error refreshing details after edit: ${e.toString()}",
      );
    } finally {
      isProcessingAction.value = false;
    }
  }

  void confirmDeletePost() async {
    String? itemId = rxItemModel.value.id;
    List<String>? imagesToDelete = List<String>.from(
      rxItemModel.value.imageUrls ?? [],
    );
    if (itemId == null) {
      SnackbarService.showError("Cannot delete item: Item ID is missing.");
      return;
    }
    isProcessingAction.value = true;
    LoggerService.logInfo(
      _className,
      'confirmDeletePost',
      'Attempting to delete item ID: $itemId. Images: ${imagesToDelete.length}',
    );
    try {
      await _lfRepository.deleteLostFoundItemWithImages(itemId, imagesToDelete);
      LoggerService.logInfo(
        _className,
        'confirmDeletePost',
        'Repository delete call completed for item ID: $itemId.',
      );
      await _notifyLostAndFoundListController(
        rxItemModel.value,
        wasDeleted: true,
      );

      Get.back(result: 'item_deleted');
      LoggerService.logInfo(
        _className,
        'confirmDeletePost',
        'Get.back called with result: item_deleted',
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'confirmDeletePost',
        'Failed to delete post for item ID: $itemId. Error: $e',
        s,
      );
      SnackbarService.showError("Failed to delete post: ${e.toString()}");
    } finally {
      isProcessingAction.value = false;
    }
  }

  Future<void> initiateChat() async {
    if (_openedFromChatFlow) {
      Get.back();
      return;
    }
    final item = rxItemModel.value;
    final currentUser = _authRepository.appUser.value;
    if (currentUser == null) {
      SnackbarService.showError("Cannot initiate chat: User not logged in.");
      return;
    }
    if (item.reporterId == currentUser.userId) {
      SnackbarService.showInfo("This is your own post.");
      return;
    }
    isLoadingChatInitiation.value = true;
    try {
      final reporterProfile = await _authRepository.getPublicUserProfile(
        item.reporterId,
      );
      final existingConversation = await _chatRepository
          .findExistingConversation(currentUser.userId, item.reporterId);

      final relatedItemToSend = RelatedItem(
        itemId: item.id!,
        itemType: 'LostFoundItemModel',
        ownerId: item.reporterId,
        title: item.title,
        imageUrl: item.imageUrls?.isNotEmpty == true
            ? item.imageUrls!.first
            : null,
        createdAt: DateTime.now(),
      );
      if (existingConversation != null) {
        Get.toNamed(
          AppRoutes.INDIVIDUAL_CHAT,
          arguments: {
            'conversation': existingConversation,
            'relatedItem': relatedItemToSend,
          },
        );
      } else {
        Get.toNamed(
          AppRoutes.INDIVIDUAL_CHAT,
          arguments: {
            'otherUserId': item.reporterId,
            'otherUserName': item.reporterName,
            'otherUserAvatarUrl': reporterProfile.userAvatarUrl,
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

  void reportPost() {
    Get.toNamed(
      AppRoutes.REPORT_SUBMISSION,
      arguments: {
        'reportedItemId': rxItemModel.value.id,
        'reportedItemTitle': rxItemModel.value.title,
        'reportType': ReportType.lostFoundItem,
      },
    );
  }

  void onImageCarouselPageChanged(int index) {
    currentImageIndex.value = index;
  }

  void navigateToFullscreenViewer() {
    if (rxItemModel.value.imageUrls != null &&
        rxItemModel.value.imageUrls!.isNotEmpty) {
      Get.toNamed(
        AppRoutes.FULLSCREEN_IMAGE_VIEWER,
        arguments: {
          'images': rxItemModel.value.imageUrls!,
          'initialIndex': currentImageIndex.value,
          'isNetwork': true,
        },
      );
    }
  }

  @override
  void onClose() {
    imagePageController.dispose();
    super.onClose();
  }
}
