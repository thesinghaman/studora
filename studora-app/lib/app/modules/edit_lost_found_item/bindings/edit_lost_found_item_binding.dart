import 'package:get/get.dart';

import 'package:studora/app/modules/edit_lost_found_item/controllers/edit_lost_found_item_controller.dart';

class EditLostFoundItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditLostFoundItemController>(
      () => EditLostFoundItemController(),
    );
  }
}
