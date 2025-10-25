import 'package:get/get.dart';
import 'package:studora/app/modules/blocked_users/controllers/blocked_users_controller.dart';
class BlockedUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlockedUsersController>(() => BlockedUsersController());
  }
}
