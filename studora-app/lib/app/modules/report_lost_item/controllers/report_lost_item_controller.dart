import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:studora/app/data/models/category_model.dart'
    as app_category_model;
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/data/models/user_model.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:path/path.dart' as p;

class ReportLostItemController extends GetxController {
  static const String _className = 'ReportLostItemController';
  final LostAndFoundRepository _lostFoundRepository =
      Get.find<LostAndFoundRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController contactPreferenceController;
  var isLoading = false.obs;
  var selectedCategory = Rxn<app_category_model.CategoryModel>();
  var lostDate = Rxn<DateTime>();
  var lostTime = Rxn<TimeOfDay>();
  var pickedImages = <XFile>[].obs;
  final int maxImages = 3;
  List<app_category_model.CategoryModel> categories = [];
  @override
  void onInit() {
    super.onInit();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    locationController = TextEditingController();
    contactPreferenceController = TextEditingController();
    if (Get.arguments != null &&
        Get.arguments['categories'] is List<app_category_model.CategoryModel>) {
      categories =
          Get.arguments['categories'] as List<app_category_model.CategoryModel>;
    } else if (Get.arguments != null &&
        Get.arguments['type'] == LostFoundType.lost) {
      LoggerService.logWarning(
        _className,
        'onInit',
        'Categories not found in arguments for ReportLostItemScreen.',
      );
    }
    lostDate.value = DateTime.now();
  }

  Future<void> pickLostDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: lostDate.value ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != lostDate.value) {
      lostDate.value = picked;
    }
  }

  Future<void> pickLostTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: lostTime.value ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != lostTime.value) {
      lostTime.value = picked;
    }
  }

  void showImageSourceActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Add Photo'),
        message: const Text('Choose image source'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Camera'),
            onPressed: () {
              Navigator.pop(context);
              requestPermissionAndPickImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Gallery'),
            onPressed: () {
              Navigator.pop(context);
              requestPermissionAndPickImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> requestPermissionAndPickImage(ImageSource source) async {
    PermissionStatus status;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo? androidInfo;
    if (Platform.isAndroid) {
      androidInfo = await deviceInfo.androidInfo;
    }
    if (Platform.isIOS ||
        (Platform.isAndroid && (androidInfo?.version.sdkInt ?? 0) >= 33)) {
      status = await Permission.photos.request();
    } else if (Platform.isAndroid && (androidInfo?.version.sdkInt ?? 0) < 33) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }
    if (status.isGranted) {
      _pickImage(source);
    } else if (status.isPermanentlyDenied) {
      SnackbarService.showError(
        'Permission permanently denied. Please enable it from app settings.',
      );
      await openAppSettings();
    } else {
      SnackbarService.showError('Permission denied. Cannot pick images.');
    }
  }

  void _pickImage(ImageSource source) async {
    if (pickedImages.length >= maxImages) {
      SnackbarService.showInfo(
        'You can select a maximum of $maxImages images.',
      );
      return;
    }
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        pickedImages.add(image);
      }
    } catch (e) {
      LoggerService.logError(
        _className,
        '_pickImage',
        'Error picking image: $e',
      );
      SnackbarService.showError('Error picking image: ${e.toString()}');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < pickedImages.length) {
      pickedImages.removeAt(index);
    }
  }

  void navigateToPreviewFromThumbnail({required int startIndex}) {
    if (pickedImages.isEmpty ||
        startIndex < 0 ||
        startIndex >= pickedImages.length) {
      return;
    }
    final List<File> imageFiles = pickedImages
        .map((xfile) => File(xfile.path))
        .toList();
    Get.toNamed(
      AppRoutes.IMAGE_PREVIEW,
      arguments: {
        'images': imageFiles,
        'isNetwork': false,
        'initialIndex': startIndex,
      },
    );
  }

  Future<void> submitReportLostItem() async {
    if (!formKey.currentState!.validate()) {
      SnackbarService.showWarning('Please fill all required fields correctly.');
      return;
    }

    isLoading.value = true;
    final UserModel? currentUser = _authRepository.appUser.value;
    if (currentUser == null) {
      SnackbarService.showError('User not authenticated. Please log in.');
      isLoading.value = false;
      return;
    }
    try {
      List<String> imageUrls = [];
      if (pickedImages.isNotEmpty) {
        for (XFile xFile in pickedImages) {
          String fileName =
              '${currentUser.userId}_${DateTime.now().millisecondsSinceEpoch}${p.extension(xFile.path)}';
          final appwriteFile = appwrite.InputFile.fromPath(
            path: xFile.path,
            filename: fileName,
          );
          List<String> permissions = [
            appwrite.Permission.read(appwrite.Role.any()),
            appwrite.Permission.update(appwrite.Role.user(currentUser.userId)),
            appwrite.Permission.delete(appwrite.Role.user(currentUser.userId)),
          ];
          final uploadedFile = await _appwriteService.storage.createFile(
            bucketId: AppConstants.itemsImagesBucketId,
            fileId: appwrite.ID.unique(),
            file: appwriteFile,
            permissions: permissions,
          );
          final String fileUrl =
              "${AppwriteService.projectEndpoint}/storage/buckets/${AppConstants.itemsImagesBucketId}/files/${uploadedFile.$id}/view?project=${AppwriteService.projectId}";
          imageUrls.add(fileUrl);
          LoggerService.logInfo(
            _className,
            'submitReportLostItem',
            'Uploaded image: $fileUrl',
          );
        }
      }
      DateTime reportedDateTime = DateTime.now();
      DateTime? actualLostDateTime;
      if (lostDate.value != null) {
        actualLostDateTime = DateTime(
          lostDate.value!.year,
          lostDate.value!.month,
          lostDate.value!.day,
          lostTime.value?.hour ?? 0,
          lostTime.value?.minute ?? 0,
        );
      }
      final LostFoundItemModel newItem = LostFoundItemModel(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        type: LostFoundType.lost,
        categoryId: selectedCategory.value!.id,
        categoryName: selectedCategory.value!.name,
        dateReported: reportedDateTime,
        dateFoundOrLost: actualLostDateTime,
        location: locationController.text.trim(),
        imageUrls: imageUrls,
        reporterId: currentUser.userId,
        reporterName: currentUser.userName,
        reporterCollegeId: currentUser.collegeId,
        contactInfo: contactPreferenceController.text.trim(),
        postStatus: "Active",
        isActive: true,
        expiryDate: DateTime.now().add(const Duration(days: 90)),
      );
      await _lostFoundRepository.createLostFoundItem(newItem);

      Get.back(result: true);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'submitReportLostItem',
        'Error: $e',
        s,
      );
      SnackbarService.showError('Failed to report lost item: ${e.toString()}');

      isLoading.value = false;
    } finally {
      if ((Get.isOverlaysOpen) ||
          (Get.isBottomSheetOpen ?? false) ||
          (Get.isDialogOpen ?? false)) {
      } else {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    contactPreferenceController.dispose();
    super.onClose();
  }
}
