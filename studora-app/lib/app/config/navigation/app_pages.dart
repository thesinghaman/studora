import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studora/app/config/navigation/app_routes.dart';
import 'package:studora/app/modules/ad_detail/bindings/ad_detail_binding.dart';
import 'package:studora/app/modules/all_marketplace/bindings/all_marketplace_binding.dart';
import 'package:studora/app/modules/all_marketplace/views/all_marketplace_view.dart';
import 'package:studora/app/modules/all_rentals/bindings/all_rentals_bindings.dart';
import 'package:studora/app/modules/all_rentals/views/all_rentals_screen.dart';
import 'package:studora/app/modules/auth/controllers/verification_controller.dart';
import 'package:studora/app/modules/auth/views/forgot_password_screen.dart';
import 'package:studora/app/modules/auth/views/password_reset_confirmation_screen.dart';
import 'package:studora/app/modules/blocked_users/bindings/blocked_users_binding.dart';
import 'package:studora/app/modules/blocked_users/views/blocked_users_view.dart';
import 'package:studora/app/modules/category_listings/bindings/category_listings_binding.dart';
import 'package:studora/app/modules/category_listings/views/category_listings_screen.dart';
import 'package:studora/app/modules/change_password/bindings/change_password_binding.dart';
import 'package:studora/app/modules/change_password/views/change_password_view.dart';
import 'package:studora/app/modules/chat_user_profile/bindings/chat_user_profile_binding.dart';
import 'package:studora/app/modules/chat_user_profile/views/chat_user_profile_view.dart';
import 'package:studora/app/modules/contact_support/bindings/contact_support_binding.dart';
import 'package:studora/app/modules/contact_support/views/contact_support_view.dart';
import 'package:studora/app/modules/delete_account/bindings/delete_account_binding.dart';
import 'package:studora/app/modules/delete_account/views/delete_confirmation_view.dart';
import 'package:studora/app/modules/edit_ad/bindings/edit_ad_binding.dart';
import 'package:studora/app/modules/edit_ad/views/edit_ad_view.dart';
import 'package:studora/app/modules/edit_lost_found_item/bindings/edit_lost_found_item_binding.dart';
import 'package:studora/app/modules/edit_lost_found_item/views/edit_lost_found_item_screen.dart';
import 'package:studora/app/modules/edit_profile/bindings/edit_profile_binding.dart';
import 'package:studora/app/modules/edit_profile/views/edit_profile_view.dart';
import 'package:studora/app/modules/fullscreen_viewer/bindings/fullscreen_viewer_binding.dart';
import 'package:studora/app/modules/fullscreen_viewer/views/fullscreen_viewer_view.dart';
import 'package:studora/app/modules/help_and_faq/bindings/help_and_faq_binding.dart';
import 'package:studora/app/modules/help_and_faq/views/help_and_faq_view.dart';
import 'package:studora/app/modules/image_preview/bindings/image_preview_binding.dart';
import 'package:studora/app/modules/image_preview/views/image_preview_view.dart';
import 'package:studora/app/modules/individual_chat/bindings/individual_chat_binding.dart';
import 'package:studora/app/modules/individual_chat/views/individual_chat_view.dart';
import 'package:studora/app/modules/lost_and_found/bindings/lost_and_found_binding.dart';
import 'package:studora/app/modules/lost_and_found/views/lost_and_found_view.dart';
import 'package:studora/app/modules/lost_found_detail/bindings/lost_found_detail_binding.dart';
import 'package:studora/app/modules/lost_found_detail/views/lost_found_detail_view.dart';
import 'package:studora/app/modules/main_navigation/bindings/main_navigation_binding.dart';
import 'package:studora/app/modules/main_navigation/views/main_navigation_screen.dart';
import 'package:studora/app/modules/my_ads/bindings/my_ads_binding.dart';
import 'package:studora/app/modules/my_ads/views/my_ads_view.dart';
import 'package:studora/app/modules/onboarding/views/onboarding_screen.dart';
import 'package:studora/app/modules/auth/views/login_screen.dart';
import 'package:studora/app/modules/auth/views/signup_screen.dart';
import 'package:studora/app/modules/auth/views/verification_screen.dart';
import 'package:studora/app/modules/application_settings/views/terms_conditions_screen.dart';
import 'package:studora/app/modules/application_settings/views/privacy_policy_screen.dart';
import 'package:studora/app/bindings/application_binding.dart';
import 'package:studora/app/modules/onboarding/bindings/onboarding_binding.dart';
import 'package:studora/app/modules/auth/bindings/auth_binding.dart';
import 'package:studora/app/modules/application_settings/controllers/legal_document_controller.dart';
import 'package:studora/app/data/providers/legal_document_provider.dart';
import 'package:studora/app/data/repositories/legal_document_repository.dart';
import 'package:studora/app/modules/post_ad/bindings/post_ad_binding.dart';
import 'package:studora/app/modules/post_ad/views/post_ad_view.dart';
import 'package:studora/app/modules/report_found_item/bindings/report_found_item_binding.dart';
import 'package:studora/app/modules/report_found_item/views/report_found_item_view.dart';
import 'package:studora/app/modules/report_lost_item/bindings/report_lost_item_binding.dart';
import 'package:studora/app/modules/report_lost_item/views/report_lost_item_view.dart';
import 'package:studora/app/modules/report_submission/bindings/existing_report_detail_binding.dart';
import 'package:studora/app/modules/report_submission/bindings/report_submission_binding.dart';
import 'package:studora/app/modules/report_submission/views/existing_report_detail_view.dart';
import 'package:studora/app/modules/report_submission/views/report_submission_view.dart';
import 'package:studora/app/modules/search/bindings/search_binding.dart';
import 'package:studora/app/modules/search/views/search_view.dart';
import 'package:studora/app/modules/settings/bindings/settings_binding.dart';
import 'package:studora/app/modules/settings/views/settings_view.dart';
import 'package:studora/app/modules/splash/bindings/splash_binding.dart';
import 'package:studora/app/modules/splash/views/splash_screen.dart';
import 'package:studora/app/modules/wishlist/bindings/wishlist_binding.dart';
import 'package:studora/app/modules/wishlist/views/wishlist_screen.dart';
import 'package:studora/app/modules/privacy/bindings/privacy_binding.dart';
import 'package:studora/app/modules/privacy/views/privacy_view.dart';
import '../../modules/ad_detail/views/ad_detail_screen.dart';
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.INIT_LOADING,
      page: () =>
          const Scaffold(body: Center(child: CupertinoActivityIndicator())),
      binding: ApplicationBinding(),
    ),
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.PRIVACY,
      page: () => const PrivacyView(),
      binding: PrivacyBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.PASSWORD_RESET_CONFIRMATION,
      page: () => const PasswordResetConfirmationScreen(),
    ),
    GetPage(
      name: AppRoutes.SIGNUP,
      page: () => const SignupScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.VERIFICATION,
      page: () => const VerificationScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<VerificationController>(() => VerificationController());
      }),
    ),
    GetPage(
      name: AppRoutes.TERMS_CONDITIONS,
      page: () => const TermsConditionsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LegalDocumentProvider>(
          () => LegalDocumentProvider(),
          fenix: true,
        );
        Get.lazyPut<LegalDocumentRepository>(
          () => LegalDocumentRepository(),
          fenix: true,
        );
        Get.put<LegalDocumentController>(
          LegalDocumentController(docType: LegalDocType.terms),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.PRIVACY_POLICY,
      page: () => const PrivacyPolicyScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<LegalDocumentProvider>(
          () => LegalDocumentProvider(),
          fenix: true,
        );
        Get.lazyPut<LegalDocumentRepository>(
          () => LegalDocumentRepository(),
          fenix: true,
        );
        Get.put<LegalDocumentController>(
          LegalDocumentController(docType: LegalDocType.privacy),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.MAIN_NAVIGATION,
      page: () => const MainNavigationScreen(),
      binding: MainNavigationBinding(),
    ),
    GetPage(
      name: AppRoutes.WISHLIST,
      page: () => const WishlistScreen(),
      binding: WishlistBinding(),
    ),
    GetPage(
      name: AppRoutes.POST_ITEM,
      page: () => const PostAdScreenView(),
      binding: PostAdBinding(),
    ),
    GetPage(
      name: AppRoutes.IMAGE_PREVIEW,
      page: () => const ImagePreviewScreenView(),
      binding: ImagePreviewBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.ITEM_DETAIL,
      page: () => AdDetailScreen(),
      binding: AdDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.FULLSCREEN_IMAGE_VIEWER,
      page: () => const FullscreenViewerView(),
      binding: FullscreenViewerBinding(),
    ),
    GetPage(
      name: AppRoutes.EDIT_ITEM,
      page: () => const EditAdView(),
      binding: EditAdBinding(),
    ),
    GetPage(
      name: AppRoutes.SEARCH,
      page: () => SearchView(),
      binding: SearchBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.ALL_ITEMS_RENTALS,
      page: () => AllRentalsView(),
      binding: AllRentalsBinding(),
    ),
    GetPage(
      name: AppRoutes.ALL_ITEMS_MARKETPLACE,
      page: () => AllMarketplaceView(),
      binding: AllMarketplaceBinding(),
    ),
    GetPage(
      name: AppRoutes.CATEGORY_LISTINGS,
      page: () => CategoryListingsScreen(),
      binding: CategoryListingsBinding(),
    ),
    GetPage(
      name: AppRoutes.REPORT_SUBMISSION,
      page: () => const ReportSubmissionView(),
      binding: ReportSubmissionBinding(),
    ),
    GetPage(
      name: AppRoutes.LOST_AND_FOUND,
      page: () => const LostAndFoundView(),
      binding: LostAndFoundBinding(),
    ),
    GetPage(
      name: AppRoutes.REPORT_LOST_ITEM,
      page: () => const ReportLostItemView(),
      binding: ReportLostItemBinding(),
    ),
    GetPage(
      name: AppRoutes.REPORT_FOUND_ITEM,
      page: () => const ReportFoundItemView(),
      binding: ReportFoundItemBinding(),
    ),
    GetPage(
      name: AppRoutes.LOST_FOUND_ITEM_DETAIL,
      page: () => const LostFoundDetailView(),
      binding: LostFoundDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.EDIT_LOST_FOUND_ITEM,
      page: () => const EditLostFoundItemScreen(),
      binding: EditLostFoundItemBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.MY_ADS,
      page: () => const MyAdsView(),
      binding: MyAdsBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.CHANGE_PASSWORD,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.HELP_FAQ,
      page: () => const HelpAndFaqView(),
      binding: HelpAndFaqBinding(),
    ),
    GetPage(
      name: AppRoutes.CONTACT_SUPPORT,
      page: () => const ContactSupportView(),
      binding: ContactSupportBinding(),
    ),
    GetPage(
      name: AppRoutes.INDIVIDUAL_CHAT,
      page: () => const IndividualChatView(),
      binding: IndividualChatBinding(),
    ),
    GetPage(
      name: AppRoutes.CHAT_USER_PROFILE,
      page: () => const ChatUserProfileView(),
      binding: ChatUserProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.DELETE_ACCOUNT,
      page: () => const DeleteConfirmationView(),
      binding: DeleteAccountBinding(),
    ),
    GetPage(
      name: AppRoutes.EXISTING_REPORT_DETAIL,
      page: () => const ExistingReportDetailView(),
      binding: ExistingReportDetailBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: AppRoutes.BLOCKED_USERS,
      page: () => const BlockedUsersView(),
      binding: BlockedUsersBinding(),
    ),
  ];
}
