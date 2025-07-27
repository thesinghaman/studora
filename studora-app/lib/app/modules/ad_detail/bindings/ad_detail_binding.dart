import 'package:get/get.dart';
import 'package:studora/app/data/providers/chat_provider.dart';
import 'package:studora/app/data/repositories/chat_repository.dart';
import 'package:studora/app/modules/ad_detail/controllers/ad_detail_controller.dart';
import 'package:studora/app/data/repositories/category_repository.dart';
import 'package:studora/app/data/providers/category_provider.dart';
class AdDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoryProvider>(() => CategoryProvider(), fenix: true);
    Get.lazyPut<CategoryRepository>(() => CategoryRepository(), fenix: true);
    Get.lazyPut<ChatProvider>(() => ChatProvider(), fenix: true);
    Get.lazyPut<ChatRepository>(() => ChatRepository());
    Get.lazyPut<AdDetailController>(() => AdDetailController());
  }
}
