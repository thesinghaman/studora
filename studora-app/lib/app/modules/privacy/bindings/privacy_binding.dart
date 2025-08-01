import 'package:get/get.dart';

import 'package:studora/app/modules/privacy/controllers/privacy_controller.dart';

class PrivacyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyController>(() => PrivacyController());
  }
}
