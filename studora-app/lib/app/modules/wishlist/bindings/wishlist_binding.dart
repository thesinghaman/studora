import 'package:get/get.dart';

import 'package:studora/app/modules/wishlist/controllers/wishlist_controller.dart';

class WishlistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WishlistController>(() => WishlistController());
  }
}
