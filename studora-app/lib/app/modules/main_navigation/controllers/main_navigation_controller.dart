import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/modules/home/views/home_view.dart';
import 'package:studora/app/modules/messages/views/messages_view.dart';
import 'package:studora/app/modules/my_ads/views/my_ads_view.dart';
import 'package:studora/app/modules/settings/views/settings_view.dart';

class MainNavigationController extends GetxController
    with WidgetsBindingObserver {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  var selectedIndex = 0.obs;
  final List<Widget> pages = [
    const HomeView(),
    const MessagesView(),
    const MyAdsView(),
    const SettingsView(),
  ];
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    _authRepository.updateUserStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _authRepository.updateUserStatus(true);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _authRepository.updateUserStatus(false);
        break;
    }
  }

  void changeTabIndex(int index) {
    selectedIndex.value = index;
  }
}
