import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class ImagePreviewController extends GetxController {
  final RxList<XFile> imagesToPreview = <XFile>[].obs;
  final RxInt currentPageIndex = 0.obs;
  late PageController pageController;
  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    List<XFile>? initialImagesFromArgs;
    int startIndexFromArgs = 0;
    if (arguments != null) {
      initialImagesFromArgs = arguments['initialImages'] as List<XFile>?;
      startIndexFromArgs = arguments['initialIndex'] as int? ?? 0;
    }
    if (initialImagesFromArgs != null && initialImagesFromArgs.isNotEmpty) {
      imagesToPreview.assignAll(initialImagesFromArgs);
    }

    if (startIndexFromArgs < 0 ||
        startIndexFromArgs >= imagesToPreview.length) {
      currentPageIndex.value = 0;
    } else {
      currentPageIndex.value = startIndexFromArgs;
    }
    pageController = PageController(initialPage: currentPageIndex.value);
  }

  void removeImage(int index) {
    if (index >= 0 && index < imagesToPreview.length) {
      imagesToPreview.removeAt(index);
      if (imagesToPreview.isEmpty) {
        currentPageIndex.value = 0;
      } else if (currentPageIndex.value >= imagesToPreview.length) {
        currentPageIndex.value = imagesToPreview.length - 1;
      }

      if (pageController.hasClients) {
        pageController.jumpToPage(currentPageIndex.value);
      }
    }
  }

  void confirmSelection() {
    if (imagesToPreview.isEmpty) {
      SnackbarService.showWarning(
        title: "No Images",
        "Please select at least one image or cancel.",
      );
      return;
    }
    Get.back(result: List<XFile>.from(imagesToPreview));
  }

  void addMoreImages() async {
    final ImagePicker picker = ImagePicker();
    int currentCount = imagesToPreview.length;
    int canAdd = 5 - currentCount;
    if (canAdd <= 0) {
      SnackbarService.showWarning(
        title: "Limit Reached",
        "You can select a maximum of 5 images.",
      );
      return;
    }
    final List<XFile> newPickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
      limit: canAdd,
    );
    if (newPickedFiles.isNotEmpty) {
      imagesToPreview.addAll(newPickedFiles);
      SnackbarService.showInfo(
        title: "Images Added",
        "${newPickedFiles.length} image(s) added.",
      );
      if (pageController.hasClients) {
        pageController.animateToPage(
          currentCount,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Future<void> cropImage(int index) async {
    if (index < 0 || index >= imagesToPreview.length) return;
    final XFile imageToCrop = imagesToPreview[index];
    try {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageToCrop.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Get.theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: Get.theme.colorScheme.primary,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            cropFrameColor: Get.theme.colorScheme.primary,
            cropGridColor: Get.theme.colorScheme.primary.withValues(alpha: 0.5),
            cropFrameStrokeWidth: 3,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            resetAspectRatioEnabled: false,
            aspectRatioLockEnabled: false,
            rectX: 1,
            rectY: 1,
            rectWidth: 1,
            rectHeight: 1,
          ),
        ],
      );
      if (croppedFile != null) {
        imagesToPreview[index] = XFile(croppedFile.path);
      }
    } catch (e) {
      LoggerService.logError(
        'ImagePreviewController',
        'cropImage',
        'Error cropping image: $e',
      );
      SnackbarService.showError("Error cropping image. Please try again.");
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
