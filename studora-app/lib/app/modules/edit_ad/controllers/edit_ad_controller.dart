import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/data/models/user_model.dart' as studora_user_model;
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/search_tag_generator.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';

class EditAdController extends GetxController {
  static const String _className = 'EditAdController';
  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late ItemModel originalItem;
  var newSelectedImages = <XFile>[].obs;
  var existingImageUrls = <String>[].obs;
  var imagesToDeleteFileIds = <String>[].obs;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController rentalTermController = TextEditingController();
  final TextEditingController propertyTypeController = TextEditingController();
  final TextEditingController amenitiesController = TextEditingController();
  var selectedCategory = RxnString();
  var selectedCondition = Rxn<ItemCondition>();
  var selectedAvailableFrom = Rxn<DateTime>();
  var selectedExpiryDate = Rxn<DateTime>();
  var isSubmitting = false.obs;
  var isRental = false.obs;
  var saleCategories = <CategoryModel>[].obs;
  var rentalCategories = <CategoryModel>[].obs;
  var currentCategories = <CategoryModel>[].obs;
  var isLoadingCategories = true.obs;
  List<ItemCondition> get productConditions => ItemCondition.values
      .where((c) => c != ItemCondition.notApplicable)
      .toList();
  String itemConditionToString(ItemCondition? condition) {
    if (condition == null) return '';
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
        return '';
    }
  }

  ItemCondition? stringToItemCondition(String? conditionStr) {
    if (conditionStr == null) return null;
    for (var enumVal in ItemCondition.values) {
      if (itemConditionToString(enumVal) == conditionStr) {
        return enumVal;
      }
    }
    final Map<String, ItemCondition> productConditionsStringsMap = {
      "New": ItemCondition.aNew,
      "Used - Like New": ItemCondition.likeNew,
      "Used - Excellent": ItemCondition.excellent,
      "Used - Good": ItemCondition.good,
      "Used - Fair": ItemCondition.fair,
    };
    return productConditionsStringsMap[conditionStr];
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ItemModel) {
      originalItem = Get.arguments as ItemModel;
      _populateFieldsFromItem(originalItem);
      _fetchCategories();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoggerService.logError(
          _className,
          'onInit',
          'No ItemModel passed as argument. Cannot edit.',
        );
        SnackbarService.showError(
          "Error: No ad data found. Please go back and try again.",
        );
        if (Get.key.currentContext != null && Get.key.currentContext!.mounted) {
          Get.back();
        }
      });
      return;
    }
    ever(isRental, (_) => _updateCurrentCategories());
  }

  void _populateFieldsFromItem(ItemModel item) {
    titleController.text = item.title;
    descriptionController.text = item.description;
    priceController.text = item.price.toString();
    locationController.text = item.location ?? '';
    isRental.value = item.isRental;
    existingImageUrls.assignAll(item.imageUrls ?? []);
    newSelectedImages.clear();
    imagesToDeleteFileIds.clear();
    selectedCategory.value = item.categoryId;
    selectedCondition.value = item.condition;
    selectedExpiryDate.value = item.expiryDate;
    if (item.isRental) {
      rentalTermController.text = item.rentalTerm ?? '';
      propertyTypeController.text = item.propertyType ?? '';
      amenitiesController.text = item.amenities?.join(', ') ?? '';
      selectedAvailableFrom.value = item.availableFrom;
    }
  }

  Future<void> _fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final allCats = await _categoryRepository.getCategories();
      saleCategories.assignAll(
        allCats.where((c) => c.type.toLowerCase() == 'sale').toList(),
      );
      rentalCategories.assignAll(
        allCats.where((c) => c.type.toLowerCase() == 'rental').toList(),
      );
      _updateCurrentCategories();
      if (selectedCategory.value != null &&
          !currentCategories.any((cat) => cat.id == selectedCategory.value)) {
        selectedCategory.value = null;
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_fetchCategories',
        'Error fetching categories: $e',
        s,
      );
      SnackbarService.showError("Failed to load categories.");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void _updateCurrentCategories() {
    currentCategories.assignAll(
      isRental.value ? rentalCategories : saleCategories,
    );
    if (selectedCategory.value != null &&
        !currentCategories.any((cat) => cat.id == selectedCategory.value)) {
      selectedCategory.value = null;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    locationController.dispose();
    rentalTermController.dispose();
    propertyTypeController.dispose();
    amenitiesController.dispose();
    super.onClose();
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) return "Camera";
    if (permission == Permission.photos) return "Photos";
    if (permission == Permission.storage) return "Storage";
    return "Required";
  }

  Future<void> showImageSourceActionSheetAndPreview(
    BuildContext context,
  ) async {
    final int currentTotalImages =
        existingImageUrls.length + newSelectedImages.length;
    if (currentTotalImages >= 5) {
      SnackbarService.showWarning(
        title: "Image Limit Reached",
        "You cannot add more than 5 images in total.",
      );
      if (newSelectedImages.isNotEmpty) {
        await _navigateToPreviewScreen(List<XFile>.from(newSelectedImages), 0);
      }
      return;
    }
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalCtx) => CupertinoActionSheet(
        title: const Text('Add Photos'),
        message: Text(
          'You can add up to ${5 - currentTotalImages} more image(s). Max 5 total.',
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Camera'),
            onPressed: () async {
              Navigator.pop(modalCtx);
              await _pickFromSourceAndNavigateToPreview(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Gallery'),
            onPressed: () async {
              Navigator.pop(modalCtx);
              await _pickFromSourceAndNavigateToPreview(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(modalCtx),
        ),
      ),
    );
  }

  Future<void> _pickFromSourceAndNavigateToPreview(ImageSource source) async {
    Permission permission;
    if (source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        permission = androidInfo.version.sdkInt >= 33
            ? Permission.photos
            : Permission.storage;
      } else {
        permission = Permission.photos;
      }
    }
    PermissionStatus status = await permission.request();
    if (!status.isGranted && !status.isLimited) {
      SnackbarService.showError(
        '${_getPermissionName(permission)} permission not granted.',
        title: "Permission Denied",
      );
      return;
    }
    List<XFile> pickedFiles = [];
    int currentTotalImages =
        existingImageUrls.length + newSelectedImages.length;
    int limit = 5 - currentTotalImages;
    if (limit <= 0) {
      SnackbarService.showWarning(
        title: "Image Limit",
        "Maximum 5 images already selected/uploaded.",
      );
      if (newSelectedImages.isNotEmpty) {
        await _navigateToPreviewScreen(List<XFile>.from(newSelectedImages), 0);
      }
      return;
    }
    if (source == ImageSource.gallery) {
      pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
    } else {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) pickedFiles.add(pickedFile);
    }
    if (pickedFiles.isNotEmpty) {
      await _navigateToPreviewScreen([
        ...newSelectedImages,
        ...pickedFiles,
      ], newSelectedImages.length);
    } else if (newSelectedImages.isNotEmpty &&
        (source == ImageSource.gallery || source == ImageSource.camera)) {
      await _navigateToPreviewScreen(List<XFile>.from(newSelectedImages), 0);
    }
  }

  Future<void> reEditNewImages() async {
    if (newSelectedImages.isEmpty) {
      SnackbarService.showInfo(
        title: "No New Images",
        "Add some new images first to edit them.",
      );
      return;
    }
    await _navigateToPreviewScreen(List<XFile>.from(newSelectedImages), 0);
  }

  Future<void> _navigateToPreviewScreen(
    List<XFile> imagesToPreview,
    int startIndex,
  ) async {
    final int maxAllowedNew = 5 - existingImageUrls.length;
    final List<XFile> actualImagesForPreview =
        imagesToPreview.length > maxAllowedNew
        ? imagesToPreview.sublist(0, maxAllowedNew)
        : imagesToPreview;
    if (imagesToPreview.length > maxAllowedNew) {
      SnackbarService.showInfo(
        title: "Image Limit",
        "Showing first $maxAllowedNew images for preview due to overall limit of 5.",
      );
    }
    final dynamic confirmedImagesRaw = await Get.toNamed(
      AppRoutes.IMAGE_PREVIEW,
      arguments: {
        'initialImages': actualImagesForPreview,
        'initialIndex': startIndex < actualImagesForPreview.length
            ? startIndex
            : 0,
        'maxImages': maxAllowedNew,
      },
    );
    if (confirmedImagesRaw is List &&
        confirmedImagesRaw.every((item) => item is XFile)) {
      newSelectedImages.assignAll(confirmedImagesRaw.cast<XFile>());
    }
  }

  void removeNewImage(int index) {
    if (index >= 0 && index < newSelectedImages.length) {
      newSelectedImages.removeAt(index);
    }
  }

  void markExistingImageForDeletion(String imageUrl) {
    if (existingImageUrls.length + newSelectedImages.length <= 1) {
      SnackbarService.showError("At least one image is required for the ad.");
      return;
    }
    if (existingImageUrls.contains(imageUrl)) {
      final fileId = _extractFileIdFromUrl(imageUrl);
      if (fileId != null) {
        imagesToDeleteFileIds.add(fileId);
        existingImageUrls.remove(imageUrl);
      } else {
        SnackbarService.showError(
          "Could not process image for deletion. Invalid URL format.",
        );
      }
    }
  }

  String? _extractFileIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.length >= 5 &&
          segments[2] == 'buckets' &&
          segments[4] == 'files') {
        return segments[5];
      }
    } catch (e) {
      LoggerService.logError(
        _className,
        '_extractFileIdFromUrl',
        'Error parsing URL $url: $e',
      );
    }
    return null;
  }

  Future<void> selectDate(
    BuildContext context, {
    bool isAvailableFrom = false,
  }) async {
    final DateTime initial = isAvailableFrom
        ? (selectedAvailableFrom.value ?? DateTime.now())
        : (selectedExpiryDate.value ??
              DateTime.now().add(const Duration(days: 30)));
    final DateTime first = isAvailableFrom
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 1));
    final DateTime last = DateTime.now().add(const Duration(days: 365 * 2));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Get.theme.copyWith(
          colorScheme: Get.theme.colorScheme.copyWith(
            primary: Get.theme.colorScheme.primary,
            onPrimary: Get.theme.colorScheme.onPrimary,
            onSurface: Get.theme.colorScheme.onSurface,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.primary,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (isAvailableFrom) {
        selectedAvailableFrom.value = picked;
      } else {
        selectedExpiryDate.value = picked;
      }
    }
  }

  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) {
      SnackbarService.showWarning(
        title: "Validation Error",
        "Please fill all required fields correctly.",
      );
      return;
    }
    if (existingImageUrls.isEmpty && newSelectedImages.isEmpty) {
      SnackbarService.showError(
        'Please ensure there is at least one image for the ad.',
      );
      return;
    }
    if (selectedCategory.value == null) {
      SnackbarService.showError('Please select a category.');
      return;
    }
    if (!isRental.value && selectedCondition.value == null) {
      SnackbarService.showError('Please select the item condition.');
      return;
    }
    if (selectedExpiryDate.value == null) {
      SnackbarService.showError('Please set an expiry date.');
      return;
    }
    if (selectedExpiryDate.value!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      SnackbarService.showError('Expiry date cannot be in the past.');
      return;
    }
    final List<String> searchTags = SearchTagGenerator.generateTags(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      categoryName: selectedCategory.value,
    );
    isSubmitting.value = true;
    try {
      studora_user_model.UserModel? currentUser = await _authRepository
          .getCurrentAppUser();
      if (currentUser == null || currentUser.collegeId == null) {
        SnackbarService.showError(
          "User not authenticated or college info missing. Please re-login.",
        );
        isSubmitting.value = false;
        return;
      }
      final updatedItemData = originalItem.copyWith(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price:
            double.tryParse(priceController.text.trim()) ?? originalItem.price,
        categoryId: selectedCategory.value,
        location: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
        condition: !isRental.value ? selectedCondition.value : null,
        rentalTerm:
            isRental.value && rentalTermController.text.trim().isNotEmpty
            ? rentalTermController.text.trim()
            : null,
        availableFrom: isRental.value ? selectedAvailableFrom.value : null,
        propertyType:
            isRental.value && propertyTypeController.text.trim().isNotEmpty
            ? propertyTypeController.text.trim()
            : null,
        amenities: isRental.value && amenitiesController.text.trim().isNotEmpty
            ? amenitiesController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : null,
        expiryDate: selectedExpiryDate.value,
        searchTags: searchTags,
      );
      final ItemModel successfullyUpdatedItem = await _itemRepository
          .updateItem(
            updatedItemData: updatedItemData,
            newImagesToUpload: newSelectedImages.toList(),
            imageFileIdsToDelete: imagesToDeleteFileIds.toList(),
            bucketId: AppConstants.itemsImagesBucketId,
          );

      try {
        await _chatRepository.updateConversationsOnAdUpdate(
          successfullyUpdatedItem.id,
          successfullyUpdatedItem.title,
          successfullyUpdatedItem.imageUrls?.first,
        );
      } catch (e, s) {
        LoggerService.logError(
          _className,
          'saveChanges -> updateConversations',
          'Failed to trigger conversation update for ad item: $e',
          s,
        );
      }

      Get.back(result: successfullyUpdatedItem);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'saveChanges',
        'Error updating ad: $e',
        s,
      );
      SnackbarService.showError("Failed to update ad: ${e.toString()}");
    } finally {
      isSubmitting.value = false;
    }
  }
}
