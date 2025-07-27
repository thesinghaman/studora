import 'package:get/get.dart';

import 'package:studora/app/modules/help_and_faq/controllers/help_and_faq_controller.dart';

class HelpAndFaqBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpAndFaqController>(() => HelpAndFaqController());
  }
}
