import 'package:get/get.dart';

import 'package:studora/app/data/providers/lost_and_found_provider.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';
import 'package:studora/app/modules/lost_and_found/controllers/lost_and_found_controller.dart';

class LostAndFoundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LostAndFoundProvider>(() => LostAndFoundProvider());
    Get.lazyPut<LostAndFoundRepository>(() => LostAndFoundRepository());
    Get.lazyPut<LostAndFoundController>(() => LostAndFoundController());
  }
}
