import 'package:get/get.dart';
import 'package:studora/app/modules/all_marketplace/controllers/all_marketplace_controller.dart';
class AllMarketplaceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllMarketplaceController>(() => AllMarketplaceController());
  }
}
