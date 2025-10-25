import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/fullscreen_viewer/controllers/fullscreen_viewer_controller.dart';

class FullscreenViewerView extends GetView<FullscreenViewerController> {
  const FullscreenViewerView({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar:
            controller.controlsVisible.value &&
                controller.imagePathsOrUrls.isNotEmpty
            ? AppBar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: controller.closePreview,
                  tooltip: "Close",
                ),
                title: Text(
                  controller.imagePathsOrUrls.isNotEmpty
                      ? "${controller.currentIndex.value + 1} of ${controller.imagePathsOrUrls.length}"
                      : "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                centerTitle: true,
              )
            : null,
        body: GestureDetector(
          onTap: controller.toggleControls,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (controller.imagePathsOrUrls.isEmpty)
                const Center(
                  child: Text(
                    "No images.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                PageView.builder(
                  controller: controller.pageController,
                  itemCount: controller.imagePathsOrUrls.length,
                  onPageChanged: controller.onPageChanged,
                  itemBuilder: (context, index) {
                    final imagePath = controller.imagePathsOrUrls[index];
                    Widget imageContent;
                    if (imagePath.startsWith('http')) {
                      imageContent = Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CupertinoActivityIndicator(
                              color: Colors.white70,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                      );
                    } else if (File(imagePath).existsSync()) {
                      imageContent = Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                      );
                    } else {
                      imageContent = const Center(
                        child: Icon(
                          CupertinoIcons.photo_on_rectangle,
                          color: Colors.white54,
                          size: 40,
                        ),
                      );
                    }
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: Center(child: imageContent),
                    );
                  },
                ),

              if (controller.controlsVisible.value &&
                  controller.imagePathsOrUrls.length > 1)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      controller.imagePathsOrUrls.length,
                      (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: controller.currentIndex.value == index
                              ? 20.0
                              : 8.0,
                          decoration: BoxDecoration(
                            color: controller.currentIndex.value == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
