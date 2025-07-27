import 'package:get/get.dart';

import 'package:studora/app/modules/report_lost_item/controllers/report_lost_item_controller.dart';

class ReportLostItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportLostItemController>(() => ReportLostItemController());
  }
}
