import 'package:get/get.dart';

import 'package:studora/app/data/providers/item_provider.dart';
import 'package:studora/app/data/providers/lost_and_found_provider.dart';
import 'package:studora/app/modules/my_ads/controllers/my_ads_controller.dart';
import 'package:studora/app/data/repositories/item_repository.dart';
import 'package:studora/app/data/repositories/lost_and_found_repository.dart';

class MyAdsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ItemProvider>(ItemProvider(), permanent: true);
    Get.put<LostAndFoundProvider>(LostAndFoundProvider(), permanent: true);
    Get.lazyPut<ItemRepository>(() => ItemRepository(), fenix: true);
    Get.lazyPut<LostAndFoundRepository>(
      () => LostAndFoundRepository(),
      fenix: true,
    );
    Get.put<MyAdsController>(MyAdsController(), permanent: true);
  }
}
