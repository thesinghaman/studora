import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/models/item_model.dart' as studora_item_model;
import 'package:studora/app/data/models/user_model.dart' as studora_user_model;
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/search_tag_generator.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';

enum ListingType { sale, rent }

final List<String> _productConditions = [
  "New",
  "Used - Like New",
  "Used - Excellent",
  "Used - Good",
  "Used - Fair",
];

class PostAdController extends GetxController {
  static const String _className = 'PostAdController';
  final ItemRepository _itemRepository = Get.find<ItemRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  var selectedImages = <XFile>[].obs;
  var listingType = ListingType.sale.obs;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController rentalTermController = TextEditingController();
  final TextEditingController propertyTypeController = TextEditingController();
  final TextEditingController amenitiesController = TextEditingController();
  var selectedCategory = RxnString();
  var selectedCondition = RxnString();
  var selectedAvailableFrom = Rxn<DateTime>();
  var selectedExpiryDate = Rxn<DateTime>();
  var isSubmitting = false.obs;
  var saleCategories = <CategoryModel>[].obs;
  var rentalCategories = <CategoryModel>[].obs;
  var currentCategories = <CategoryModel>[].obs;
  var isLoadingCategories = false.obs;
  List<String> get productConditions => _productConditions;
  @override
  void onInit() {
    super.onInit();
    _fetchCategories();
    selectedExpiryDate.value = DateTime.now().add(const Duration(days: 30));
    ever(listingType, (_) {
      _updateCurrentCategories();
      _clearConditionalFields();
    });
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
      LoggerService.logInfo(
        _className,
        '_fetchCategories',
        'Categories loaded: ${saleCategories.length} sale, ${rentalCategories.length} rental.',
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_fetchCategories',
        'Error fetching categories: $e',
        s,
      );
      SnackbarService.showError(
        "Failed to load categories. Please try again later.",
      );
      saleCategories.clear();
      rentalCategories.clear();
      currentCategories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void _updateCurrentCategories() {
    currentCategories.assignAll(
      listingType.value == ListingType.sale ? saleCategories : rentalCategories,
    );
    selectedCategory.value = null;
  }

  void _clearConditionalFields() {
    if (listingType.value == ListingType.sale) {
      rentalTermController.clear();
      selectedAvailableFrom.value = null;
      propertyTypeController.clear();
      amenitiesController.clear();
    } else {
      selectedCondition.value = null;
    }
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
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext modalCtx) => CupertinoActionSheet(
        title: const Text('Add Photos'),
        message: const Text('Select up to 5 images for your listing.'),
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
        '${_getPermissionName(permission)} permission not granted. Please enable it in settings.',
        title: "Permission Denied",
      );
      return;
    }
    List<XFile> pickedFiles = [];
    int currentImageCount = selectedImages.length;
    int limit = 5 - currentImageCount;
    if (limit <= 0 && source == ImageSource.gallery) {
      SnackbarService.showWarning(
        title: "Image Limit",
        "You have already selected 5 images.",
      );
      await _navigateToPreviewScreen(List<XFile>.from(selectedImages), 0);
      return;
    }
    if (source == ImageSource.gallery) {
      if (limit > 0) {
        pickedFiles = await _picker.pickMultiImage(
          imageQuality: 70,
          limit: limit,
        );
      }
    } else {
      if (limit > 0) {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
        );
        if (pickedFile != null) {
          pickedFiles.add(pickedFile);
        }
      } else {
        SnackbarService.showWarning(
          title: "Image Limit",
          "You have already selected 5 images.",
        );
        await _navigateToPreviewScreen(List<XFile>.from(selectedImages), 0);
        return;
      }
    }
    if (pickedFiles.isNotEmpty) {
      await _navigateToPreviewScreen([
        ...selectedImages,
        ...pickedFiles,
      ], currentImageCount);
    } else if (selectedImages.isNotEmpty &&
        (source == ImageSource.gallery || source == ImageSource.camera)) {
      await _navigateToPreviewScreen(List<XFile>.from(selectedImages), 0);
    }
  }

  Future<void> reEditSelectedImages() async {
    if (selectedImages.isEmpty) {
      SnackbarService.showInfo(
        title: "No Images",
        "Add some images first by tapping the camera icon.",
      );
      return;
    }
    await _navigateToPreviewScreen(List<XFile>.from(selectedImages), 0);
  }

  Future<void> _navigateToPreviewScreen(
    List<XFile> images,
    int startIndex,
  ) async {
    final dynamic confirmedImagesRaw = await Get.toNamed(
      AppRoutes.IMAGE_PREVIEW,
      arguments: {
        'initialImages': images,
        'initialIndex': startIndex < images.length ? startIndex : 0,
      },
    );
    if (confirmedImagesRaw != null && confirmedImagesRaw is List) {
      if (confirmedImagesRaw.every((item) => item is XFile)) {
        final List<XFile> confirmedImages = confirmedImagesRaw.cast<XFile>();
        selectedImages.assignAll(confirmedImages);
      } else {
        LoggerService.logWarning(
          _className,
          '_navigateToPreviewScreen',
          'Image preview returned List with non-XFile items.',
        );
      }
    } else if (confirmedImagesRaw == null) {
      LoggerService.logInfo(
        _className,
        '_navigateToPreviewScreen',
        'Image preview cancelled or returned null.',
      );
    } else {
      LoggerService.logWarning(
        _className,
        '_navigateToPreviewScreen',
        'Image preview returned unexpected type: ${confirmedImagesRaw.runtimeType}',
      );
    }
  }

  void removeImageFromPostAdScreen(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
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
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      if (isAvailableFrom) {
        selectedAvailableFrom.value = picked;
      } else {
        selectedExpiryDate.value = picked;
      }
    }
  }

  ItemCondition _mapConditionStringToEnum(String? conditionStr) {
    if (conditionStr == null) return ItemCondition.notApplicable;
    switch (conditionStr) {
      case "New":
        return ItemCondition.aNew;
      case "Used - Like New":
        return ItemCondition.likeNew;
      case "Used - Excellent":
        return ItemCondition.excellent;
      case "Used - Good":
        return ItemCondition.good;
      case "Used - Fair":
        return ItemCondition.fair;
      default:
        return ItemCondition.notApplicable;
    }
  }

  Future<void> submitAd() async {
    if (!formKey.currentState!.validate()) {
      SnackbarService.showWarning(
        title: "Validation Error",
        "Please fill all required fields correctly.",
      );
      return;
    }
    if (selectedImages.isEmpty) {
      SnackbarService.showError('Please add at least one image.');
      return;
    }
    if (selectedCategory.value == null) {
      SnackbarService.showError('Please select a category.');
      return;
    }
    if (selectedExpiryDate.value == null) {
      SnackbarService.showError('Please set an expiry date.');
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
      final newItemDraft = studora_item_model.ItemModel(
        id: '',
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.tryParse(priceController.text.trim()) ?? 0.0,
        currency: "INR",
        categoryId: selectedCategory.value!,
        location: locationController.text.trim().isNotEmpty
            ? locationController.text.trim()
            : null,
        datePosted: DateTime.now(),
        sellerId: currentUser.userId,
        sellerName: currentUser.userName,
        sellerProfilePicUrl: currentUser.userAvatarUrl,
        collegeId: currentUser.collegeId!,
        isRental: listingType.value == ListingType.rent,
        condition: listingType.value == ListingType.sale
            ? _mapConditionStringToEnum(selectedCondition.value)
            : null,
        rentalTerm:
            listingType.value == ListingType.rent &&
                rentalTermController.text.trim().isNotEmpty
            ? rentalTermController.text.trim()
            : null,
        availableFrom: listingType.value == ListingType.rent
            ? selectedAvailableFrom.value
            : null,
        propertyType:
            listingType.value == ListingType.rent &&
                propertyTypeController.text.trim().isNotEmpty
            ? propertyTypeController.text.trim()
            : null,
        amenities:
            listingType.value == ListingType.rent &&
                amenitiesController.text.trim().isNotEmpty
            ? amenitiesController.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : null,
        expiryDate: selectedExpiryDate.value!,
        isActive: true,
        adStatus: "Active",
        searchTags: searchTags,
      );
      LoggerService.logInfo(
        _className,
        'submitAd',
        'Attempting to create ad: ${newItemDraft.title}',
      );
      await _itemRepository.createItem(
        itemDraft: newItemDraft,
        imagesToUpload: selectedImages.toList(),
        bucketId: AppConstants.itemsImagesBucketId,
      );

      Get.offAllNamed(AppRoutes.MAIN_NAVIGATION);

      SnackbarService.showSuccess(
        title: "Ad Posted!",
        "${newItemDraft.title} is now live.",
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'submitAd',
        'Error submitting ad: $e',
        s,
      );
      SnackbarService.showError("Failed to post ad: ${e.toString()}");
    } finally {
      isSubmitting.value = false;
    }
  }
}
