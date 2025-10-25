import 'package:get/get.dart';

import 'package:studora/app/modules/individual_chat/controllers/individual_chat_controller.dart';

class IndividualChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IndividualChatController>(() => IndividualChatController());
  }
}
