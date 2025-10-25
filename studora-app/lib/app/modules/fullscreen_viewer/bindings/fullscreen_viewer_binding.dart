import 'package:get/get.dart';

import 'package:studora/app/modules/fullscreen_viewer/controllers/fullscreen_viewer_controller.dart';

class FullscreenViewerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FullscreenViewerController>(() => FullscreenViewerController());
  }
}
