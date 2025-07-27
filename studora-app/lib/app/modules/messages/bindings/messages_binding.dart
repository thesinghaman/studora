import 'package:get/get.dart';

import 'package:studora/app/data/providers/chat_provider.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';

class MessagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatProvider>(() => ChatProvider(), fenix: true);
    Get.lazyPut<ChatRepository>(() => ChatRepository(), fenix: true);
  }
}
