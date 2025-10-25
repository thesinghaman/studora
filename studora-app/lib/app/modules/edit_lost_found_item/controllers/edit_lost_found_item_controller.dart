import 'dart:io';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';

class EditLostFoundItemController extends GetxController {
  static const String _className = 'EditLostFoundItemController';
  final LostAndFoundRepository _lfRepository =
      Get.find<LostAndFoundRepository>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late LostFoundItemModel originalItem;
  late LostFoundType itemType;

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactInfoController = TextEditingController();

  var newSelectedImages = <XFile>[].obs;
  var existingImageUrls = <String>[].obs;
  var imagesToDeleteFileIds = <String>[].obs;
  var selectedCategory = RxnString();
  var selectedDateReported = Rxn<DateTime>();
  var selectedTimeReported = Rxn<TimeOfDay>();
  var selectedExpiryDate = Rxn<DateTime>();
  var isSubmitting = false.obs;

  var lfCategories = <CategoryModel>[].obs;
  var isLoadingCategories = true.obs;
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is LostFoundItemModel) {
      originalItem = Get.arguments as LostFoundItemModel;
      _populateFieldsFromItem(originalItem);
      _fetchLostFoundCategories();
    } else {
      LoggerService.logError(
        _className,
        'onInit',
        'No LostFoundItemModel passed as argument.',
      );
      SnackbarService.showError(
        "Error: No item data found. Please go back and try again.",
      );
      if (Get.key.currentState?.canPop() == true) {
        Get.back();
      }
    }
  }

  Future<void> _fetchLostFoundCategories() async {
    isLoadingCategories.value = true;
    try {
      final allCategories = await _categoryRepository.getCategories();
      lfCategories.assignAll(
        allCategories.where((cat) => cat.type.toLowerCase() == 'lf').toList(),
      );

      if (selectedCategory.value != null &&
          !lfCategories.any((cat) => cat.id == selectedCategory.value)) {
        LoggerService.logWarning(
          _className,
          '_fetchLostFoundCategories',
          'Previously selected category ${selectedCategory.value} is no longer valid or available.',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        '_fetchLostFoundCategories',
        'Error fetching L&F categories: $e',
        s,
      );
      SnackbarService.showError("Failed to load categories.");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void _populateFieldsFromItem(LostFoundItemModel item) {
    itemType = item.type;
    itemNameController.text = item.title;
    descriptionController.text = item.description;
    locationController.text = item.location;
    contactInfoController.text = item.contactInfo ?? '';

    selectedCategory.value = item.categoryId;
    selectedDateReported.value = item.dateReported;
    selectedTimeReported.value = TimeOfDay.fromDateTime(item.dateReported);
    selectedExpiryDate.value = item.expiryDate;
    existingImageUrls.assignAll(item.imageUrls ?? []);
    newSelectedImages.clear();
    imagesToDeleteFileIds.clear();
  }

  @override
  void onClose() {
    itemNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    contactInfoController.dispose();
    super.onClose();
  }

  String _getPermissionName(Permission permission) {
    if (permission == Permission.camera) return "Camera";
    if (permission == Permission.photos) return "Photos";
    if (permission == Permission.storage) return "Storage";
    return "Required";
  }

  Future<void> requestPermissionAndPickImages(
    ImageSource source,
    BuildContext context,
  ) async {
    if (!context.mounted) return;
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
    if (status.isGranted || status.isLimited) {
      List<XFile> pickedFilesResult = [];
      int currentTotalImages =
          existingImageUrls.length + newSelectedImages.length;
      int maxImagesToPick = 3 - currentTotalImages;
      if (maxImagesToPick <= 0) {
        SnackbarService.showWarning(
          title: "Image Limit",
          "Maximum 3 images already selected/uploaded.",
        );
        return;
      }
      if (source == ImageSource.gallery) {
        pickedFilesResult = await _picker.pickMultiImage(
          imageQuality: 70,
          requestFullMetadata: false,
        );
      } else {
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          requestFullMetadata: false,
        );
        if (pickedFile != null) pickedFilesResult.add(pickedFile);
      }
      if (pickedFilesResult.isNotEmpty) {
        List<XFile> combinedNewImages = List.from(newSelectedImages)
          ..addAll(pickedFilesResult);
        int totalAfterAdding =
            existingImageUrls.length + combinedNewImages.length;
        if (totalAfterAdding > 3) {
          int overflow = totalAfterAdding - 3;
          combinedNewImages.removeRange(
            combinedNewImages.length - overflow,
            combinedNewImages.length,
          );
          SnackbarService.showInfo(
            title: "Image Limit",
            "Maximum 3 images. Some new images were not added.",
          );
        }
        newSelectedImages.assignAll(combinedNewImages);
      }
    } else {
      SnackbarService.showError(
        '${_getPermissionName(permission)} permission not granted.',
        title: "Permission Denied",
      );
    }
  }

  void removeNewImage(int index) {
    if (index >= 0 && index < newSelectedImages.length) {
      newSelectedImages.removeAt(index);
    }
  }

  void markExistingImageForDeletion(String imageUrl) {
    if (existingImageUrls.length + newSelectedImages.length <= 1) {
      SnackbarService.showError(
        "At least one image is required for the report.",
      );
      return;
    }
    if (existingImageUrls.contains(imageUrl)) {
      final fileId = _extractFileIdFromUrl(imageUrl);
      if (fileId != null && fileId.isNotEmpty) {
        imagesToDeleteFileIds.add(fileId);
        existingImageUrls.remove(imageUrl);
      } else {
        LoggerService.logWarning(
          _className,
          'markExistingImageForDeletion',
          'Could not extract valid fileId from URL for deletion: $imageUrl.',
        );
      }
    }
  }

  String? _extractFileIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      var segments = uri.pathSegments;
      int filesSegmentIndex = segments.indexOf('files');
      if (filesSegmentIndex != -1 && filesSegmentIndex < segments.length - 1) {
        String potentialFileId = segments[filesSegmentIndex + 1];
        if (potentialFileId.isNotEmpty &&
            potentialFileId.length < 100 &&
            !potentialFileId.contains('/')) {
          return potentialFileId;
        }
      }
    } catch (e) {
      LoggerService.logError(
        _className,
        '_extractFileIdFromUrl',
        'Error parsing URL $url: $e',
      );
    }
    LoggerService.logWarning(
      _className,
      '_extractFileIdFromUrl',
      'Failed to extract fileId from URL: $url',
    );
    return null;
  }

  Future<void> selectDate(
    BuildContext context, {
    bool isDateReported = false,
  }) async {
    final DateTime initial = isDateReported
        ? (selectedDateReported.value ?? DateTime.now())
        : (selectedExpiryDate.value ??
              DateTime.now().add(const Duration(days: 15)));
    final DateTime first = isDateReported
        ? DateTime(DateTime.now().year - 1)
        : DateTime.now().add(const Duration(days: 1));
    final DateTime last = isDateReported
        ? DateTime.now()
        : DateTime.now().add(const Duration(days: 365));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      if (isDateReported) {
        selectedDateReported.value = picked;
      } else {
        selectedExpiryDate.value = picked;
      }
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay initial = selectedTimeReported.value ?? TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      selectedTimeReported.value = picked;
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
        'Please ensure there is at least one image for the report.',
      );
      return;
    }
    if (selectedCategory.value == null) {
      SnackbarService.showError('Please select a category.');
      return;
    }
    if (selectedDateReported.value == null) {
      SnackbarService.showError('Please select the date reported/found.');
      return;
    }
    if (selectedExpiryDate.value == null) {
      SnackbarService.showError('Please set an expiry date for the post.');
      return;
    }
    if (selectedExpiryDate.value!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      SnackbarService.showError('Expiry date cannot be in the past.');
      return;
    }
    isSubmitting.value = true;
    try {
      List<String> finalImageUrls = List.from(existingImageUrls);
      if (imagesToDeleteFileIds.isNotEmpty) {
        await _lfRepository.deleteSpecifiedImages(
          imagesToDeleteFileIds.toList(),
          AppConstants.itemsImagesBucketId,
        );
      }
      if (newSelectedImages.isNotEmpty) {
        final uploadedUrls = await _lfRepository.uploadAndGetImageUrls(
          newSelectedImages.toList(),
          AppConstants.itemsImagesBucketId,
        );
        finalImageUrls.addAll(uploadedUrls);
      }
      DateTime finalDateTimeReported = selectedDateReported.value!;
      if (selectedTimeReported.value != null) {
        finalDateTimeReported = DateTime(
          selectedDateReported.value!.year,
          selectedDateReported.value!.month,
          selectedDateReported.value!.day,
          selectedTimeReported.value!.hour,
          selectedTimeReported.value!.minute,
        );
      }
      final updatedData = <String, dynamic>{
        'title': itemNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'categoryId': selectedCategory.value,
        'location': locationController.text.trim(),
        'contactInfo': contactInfoController.text.trim(),
        'dateReported': finalDateTimeReported.toIso8601String(),
        'expiryDate': selectedExpiryDate.value!.toIso8601String(),
        'imageUrls': finalImageUrls.isNotEmpty ? finalImageUrls : null,
      };

      final selectedCatModel = lfCategories.firstWhereOrNull(
        (c) => c.id == selectedCategory.value,
      );
      if (selectedCatModel != null) {
        updatedData['categoryName'] = selectedCatModel.name;
      }
      final LostFoundItemModel successfullyUpdatedItem = await _lfRepository
          .updateLostFoundItem(originalItem.id!, updatedData);

      try {
        if (originalItem.id != null) {
          await _chatRepository.updateConversationsOnAdUpdate(
            originalItem.id!,
            successfullyUpdatedItem.title,
            successfullyUpdatedItem.imageUrls?.first,
          );
        }
      } catch (e, s) {
        LoggerService.logError(
          _className,
          'saveChanges -> updateConversations',
          'Failed to trigger conversation update for L&F item: $e',
          s,
        );
      }

      Get.back(result: successfullyUpdatedItem);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'saveChanges',
        'Error updating L&F item: $e',
        s,
      );
      SnackbarService.showError("Failed to update report: ${e.toString()}");
    } finally {
      isSubmitting.value = false;
    }
  }
}
