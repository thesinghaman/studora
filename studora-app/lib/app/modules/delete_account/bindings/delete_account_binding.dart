import 'package:get/get.dart';

import 'package:studora/app/modules/delete_account/controllers/delete_account_controller.dart';

class DeleteAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeleteAccountController>(() => DeleteAccountController());
  }
}
