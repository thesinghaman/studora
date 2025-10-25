import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/onboarding_item_model.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/services/storage_service.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  var currentPage = 0.0.obs;
  final StorageService _storageService = Get.find<StorageService>();
  final List<OnboardingItemModel> onboardingPages = [
    OnboardingItemModel(
      imagePath: "assets/images/onboarding_1.png",
      title: "Welcome to Studora!",
      description:
          "Your campus, connected. Discover everything your college community has to offer.",
    ),
    OnboardingItemModel(
      imagePath: "assets/images/onboarding_2.png",
      title: "Trade Smart, Not Hard",
      description:
          "Easily buy and sell textbooks, notes, gadgets, and more with fellow students.",
    ),
    OnboardingItemModel(
      imagePath: "assets/images/onboarding_3.png",
      title: "Find Your Space & Lost Items",
      description:
          "Looking for a place to stay or found something someone lost? We've got you covered.",
    ),
  ];
  @override
  void onInit() {
    super.onInit();
    pageController.addListener(() {
      currentPage.value = pageController.page ?? 0.0;
    });
  }

  void navigateToNextPageOrLogin() {
    if (currentPage.value < onboardingPages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      navigateToLogin();
    }
  }

  void navigateToLogin() async {
    await _storageService.setOnboardingComplete(true);
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
