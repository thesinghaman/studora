import 'package:get/get.dart';

import 'package:studora/app/modules/report_submission/controllers/existing_report_detail_controller.dart';

class ExistingReportDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExistingReportDetailController>(
      () => ExistingReportDetailController(),
    );
  }
}
