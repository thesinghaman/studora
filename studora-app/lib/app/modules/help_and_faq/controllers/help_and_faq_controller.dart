import 'package:get/get.dart';

import 'package:studora/app/config/navigation/app_routes.dart';

class FaqItem {
  final String question;
  final String answer;
  FaqItem({required this.question, required this.answer});
}

class HelpAndFaqController extends GetxController {
  var expandedIndex = Rxn<int>();

  final List<FaqItem> faqItems = [
    FaqItem(
      question: "How do I post an item for sale or rent?",
      answer:
          "To post an item, navigate to the 'Post Ad' section from the main menu or home screen. Fill in the required details such as title, description, price, category, and add relevant photos. For rentals, you can also specify rental terms, availability, and amenities.",
    ),
    FaqItem(
      question: "How can I edit or delete my existing listings?",
      answer:
          "You can manage your listings from the 'My Ads' tab. Find the ad you wish to modify and tap on it to view details. You should see an option or menu (often three dots) that allows you to 'Edit' or 'Delete' the listing. For Lost & Found posts, similar options are available to edit or mark as resolved/delete.",
    ),
    FaqItem(
      question: "What should I do if I've lost an item?",
      answer:
          "Go to the 'Lost & Found' section and tap on the 'Report Lost Item' button. Provide as much detail as possible about the item, including its name, description, last known location, and date/time lost. Adding a photo can also be very helpful.",
    ),
    FaqItem(
      question: "What should I do if I've found an item?",
      answer:
          "If you've found an item, please report it in the 'Lost & Found' section by tapping 'Report Found Item'. Describe the item, where and when you found it, and provide contact information or details about where you've handed it in (e.g., campus security).",
    ),
    FaqItem(
      question: "How does messaging work?",
      answer:
          "When you find an item you're interested in (either for sale, rent, or a found item you might own), you can usually tap a 'Chat' or 'Contact Seller/Finder' button on the item's detail page. This will open a direct message with the other user to discuss the item.",
    ),
    FaqItem(
      question: "Is my personal information safe?",
      answer:
          "We take your privacy seriously. Please review our Privacy Policy for detailed information on how we collect, use, and protect your data. We encourage users to communicate within the app and be cautious about sharing excessive personal details.",
    ),
    FaqItem(
      question: "How can I report an inappropriate listing or user?",
      answer:
          "On item detail pages and user profiles, look for a 'Report' option (often a flag icon or under a menu). Select the reason for your report and provide any necessary details. Our team will review reports and take appropriate action.",
    ),
    FaqItem(
      question: "Can I change my password or email?",
      answer:
          "You can change your password through the 'Settings' screen under 'Account'. Currently, changing your registered email address might require contacting support, depending on the app's specific setup.",
    ),
  ];

  void toggle(int index) {
    if (expandedIndex.value == index) {
      expandedIndex.value = null;
    } else {
      expandedIndex.value = index;
    }
  }

  void navigateToContactSupport() {
    Get.toNamed(AppRoutes.CONTACT_SUPPORT);
  }
}
