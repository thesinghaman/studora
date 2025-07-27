import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/image_preview/controllers/image_preview_controller.dart';

class ImagePreviewScreenView extends GetView<ImagePreviewController> {
  const ImagePreviewScreenView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(result: null),
        ),
        title: Obx(
          () => Text(
            controller.imagesToPreview.isEmpty
                ? "No Images"
                : "Preview (${controller.currentPageIndex.value + 1}/${controller.imagesToPreview.length})",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          Obx(
            () => controller.imagesToPreview.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.crop_rotate,
                      color: Colors.white,
                    ),
                    tooltip: "Crop Current Image",
                    onPressed: () {
                      controller.cropImage(
                        controller.pageController.page?.round() ??
                            controller.currentPageIndex.value,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => controller.imagesToPreview.length < 5
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.add_circled,
                      color: Colors.white,
                    ),
                    tooltip: "Add More",
                    onPressed: controller.addMoreImages,
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => controller.imagesToPreview.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.delete_solid,
                      color: Colors.white,
                    ),
                    tooltip: "Remove Current Image",
                    onPressed: () {
                      controller.removeImage(
                        controller.pageController.page?.round() ??
                            controller.currentPageIndex.value,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.imagesToPreview.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: Colors.grey,
                  size: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No images selected.",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.add_circled_solid),
                  label: const Text("Add Images"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: controller.addMoreImages,
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.imagesToPreview.length,
                onPageChanged: (index) {
                  controller.currentPageIndex.value = index;
                },
                itemBuilder: (context, index) {
                  return Obx(
                    () => InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.file(
                          File(controller.imagesToPreview[index].path),
                          fit: BoxFit.contain,
                          key: ValueKey(controller.imagesToPreview[index].path),
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                child: Text(
                                  "Error loading image",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: controller.confirmSelection,
                child: const Text("Confirm Selection"),
              ),
            ),
          ],
        );
      }),
    );
  }
}
