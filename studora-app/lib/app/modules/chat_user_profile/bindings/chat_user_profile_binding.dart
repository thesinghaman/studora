import 'package:get/get.dart';

import 'package:studora/app/modules/chat_user_profile/controllers/chat_user_profile_controller.dart';

class ChatUserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatUserProfileController>(() => ChatUserProfileController());
  }
}
