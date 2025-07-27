import 'package:get/get.dart';

import 'package:studora/app/modules/report_found_item/controllers/report_found_item_controller.dart';

class ReportFoundItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportFoundItemController>(() => ReportFoundItemController());
  }
}
