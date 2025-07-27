import 'package:get/get.dart';
import 'package:studora/app/modules/all_rentals/controllers/all_rentals_controller.dart';
class AllRentalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllRentalsController>(() => AllRentalsController());
  }
}
