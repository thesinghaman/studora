import 'package:get/get.dart';

import 'package:studora/app/modules/edit_ad/controllers/edit_ad_controller.dart';

class EditAdBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditAdController>(() => EditAdController());
  }
}
