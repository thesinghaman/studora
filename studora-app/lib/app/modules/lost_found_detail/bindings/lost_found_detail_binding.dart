import 'package:get/get.dart';

import 'package:studora/app/modules/lost_found_detail/controllers/lost_found_detail_controller.dart';

class LostFoundDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LostFoundDetailController>(() => LostFoundDetailController());
  }
}
