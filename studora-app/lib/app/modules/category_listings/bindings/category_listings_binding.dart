import 'package:get/get.dart';
import 'package:studora/app/modules/category_listings/controllers/category_listings_controller.dart';
class CategoryListingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryListingsController>(() => CategoryListingsController());
  }
}
