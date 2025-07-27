import 'package:get/get.dart';

import 'package:studora/app/modules/post_ad/controllers/post_ad_controller.dart';

class PostAdBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostAdController>(() => PostAdController());
  }
}
