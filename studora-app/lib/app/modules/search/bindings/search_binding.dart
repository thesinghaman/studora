import 'package:get/get.dart';

import 'package:studora/app/modules/search/controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ASearchController>(() => ASearchController(), fenix: true);
  }
}
