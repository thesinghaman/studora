import 'package:get/get.dart';

import 'package:studora/app/modules/report_submission/controllers/report_submission_controller.dart';

class ReportSubmissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportSubmissionController>(() => ReportSubmissionController());
  }
}
