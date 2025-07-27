import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:dots_indicator/dots_indicator.dart';

import 'package:studora/app/modules/onboarding/controllers/onboarding_controller.dart';
import 'package:studora/app/shared_components/widgets/animated_fade_slide.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: controller.navigateToLogin,
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                itemCount: controller.onboardingPages.length,
                itemBuilder: (context, index) {
                  final item = controller.onboardingPages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          height: screenHeight * 0.3,
                          width: screenWidth * 0.7,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              "Image for: ${item.title}",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 300),
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        AnimatedFadeSlide(
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.03),
              child: Obx(
                () => DotsIndicator(
                  dotsCount: controller.onboardingPages.length,
                  position: controller.currentPage.value,
                  decorator: DotsDecorator(
                    activeColor: Theme.of(context).colorScheme.primary,
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[400]!,
                    size: const Size.square(9.0),
                    activeSize: const Size(18.0, 9.0),
                    activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.02,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.navigateToNextPageOrLogin,
                    child: Text(
                      controller.currentPage.value <
                              controller.onboardingPages.length - 1
                          ? "Next"
                          : "Get Started",
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}
