import 'dart:async';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class FullscreenViewerController extends GetxController {
  final RxList<String> imagePathsOrUrls = <String>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool controlsVisible = true.obs;

  late PageController pageController;
  Timer? _controlsTimeoutTimer;
  final Duration controlsTimeoutDuration = const Duration(seconds: 3);
  @override
  void onInit() {
    super.onInit();
    _loadArguments();
    pageController = PageController(initialPage: currentIndex.value);
    _startControlsTimeout();
  }

  void _loadArguments() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      if (arguments['images'] is List) {
        var rawImages = arguments['images'] as List;
        imagePathsOrUrls.assignAll(rawImages.whereType<String>().toList());
      }
      if (arguments['initialIndex'] is int) {
        int initialIdx = arguments['initialIndex'] as int;

        if (initialIdx >= 0 && initialIdx < imagePathsOrUrls.length) {
          currentIndex.value = initialIdx;
        } else if (imagePathsOrUrls.isNotEmpty) {
          currentIndex.value = 0;
        } else {}
      }
      if (imagePathsOrUrls.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackbarService.showError("No images to display.");
          Get.back();
        });
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarService.showError("Image data not found.");
        Get.back();
      });
    }
  }

  void onPageChanged(int index) {
    if (index >= 0 && index < imagePathsOrUrls.length) {
      currentIndex.value = index;
      _resetControlsTimeout();
    }
  }

  void toggleControls() {
    controlsVisible.toggle();
    if (controlsVisible.value) {
      _startControlsTimeout();
    } else {
      _controlsTimeoutTimer?.cancel();
    }
  }

  void _startControlsTimeout() {
    _controlsTimeoutTimer?.cancel();
    if (controlsVisible.value && Get.isOverlaysOpen == false) {
      _controlsTimeoutTimer = Timer(controlsTimeoutDuration, () {
        if (isClosed == false && controlsVisible.value) {
          controlsVisible.value = false;
        }
      });
    }
  }

  void _resetControlsTimeout() {
    if (controlsVisible.value) {
      _startControlsTimeout();
    }
  }

  void closePreview() {
    Get.back();
  }

  @override
  void onClose() {
    pageController.dispose();
    _controlsTimeoutTimer?.cancel();
    super.onClose();
  }
}
