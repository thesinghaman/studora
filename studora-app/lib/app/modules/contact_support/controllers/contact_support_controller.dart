import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/data/repositories/support_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class ContactSupportController extends GetxController {
  static const String _className = 'ContactSupportController';
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final SupportRepository _supportRepository = Get.put(SupportRepository());
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  var selectedIssueCategory = RxnString();
  var isLoading = false.obs;
  final List<String> issueCategories = [
    "Account & Login Issues",
    "Listing Problems (Buy/Sell/Rent)",
    "Lost & Found Enquiries",
    "Messaging & Chat",
    "Payments & Transactions (if applicable)",
    "Technical Difficulties / Bugs",
    "Feedback & Suggestions",
    "Report a User or Item",
    "Other",
  ];
  @override
  void onClose() {
    subjectController.dispose();
    messageController.dispose();
    super.onClose();
  }

  void onCategoryChanged(String? newValue) {
    selectedIssueCategory.value = newValue;
  }

  Future<void> submitSupportRequest() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedIssueCategory.value == null) {
      SnackbarService.showWarning(
        title: "Incomplete",
        "Please select an issue category.",
      );
      return;
    }
    isLoading.value = true;
    try {
      final user = _authRepository.appUser.value;
      if (user == null) {
        throw Exception("User not found. Please log in again.");
      }

      await _supportRepository.submitSupportTicket(
        userId: user.userId,
        userEmail: user.email,
        category: selectedIssueCategory.value!,
        subject: subjectController.text,
        message: messageController.text,
      );
      isLoading.value = false;
      Get.defaultDialog(
        title: "Message Sent",
        middleText:
            "Thank you for contacting support! We have received your message and will get back to you shortly.",
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
          Get.back();
        },
      );
      _clearForm();
    } catch (e) {
      isLoading.value = false;
      LoggerService.logError(
        _className,
        'submitSupportRequest',
        'Failed to submit ticket: $e',
      );
      SnackbarService.showError(
        "Could not send your message. Please try again later.",
      );
    }
  }

  void _clearForm() {
    subjectController.clear();
    messageController.clear();
    selectedIssueCategory.value = null;
  }
}
