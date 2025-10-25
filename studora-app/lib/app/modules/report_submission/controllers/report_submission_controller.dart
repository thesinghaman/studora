import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/report_model.dart';
import 'package:studora/app/data/repositories/report_repository.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class ReportSubmissionController extends GetxController {
  static const String _className = 'ReportSubmissionController';

  final ReportRepository _reportRepository = Get.find<ReportRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  late String reportedItemId;
  late String reportedItemTitle;
  late ReportType reportType;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController detailsController = TextEditingController();
  var selectedReason = RxnString();
  var isLoading = false.obs;
  List<String> get reportReasons {
    switch (reportType) {
      case ReportType.item:
        return [
          "Misleading Information",
          "Prohibited Item",
          "Scam or Fraudulent",
          "Offensive Content",
          "Item Not Available",
          "Duplicate Listing",
          "Other",
        ];
      case ReportType.user:
        return [
          "Harassment or Bullying",
          "Inappropriate Behavior/Profile",
          "Spamming",
          "Impersonation",
          "Sharing Private Information",
          "Other",
        ];
      case ReportType.lostFoundItem:
        return [
          "False Information",
          "Scam Attempt",
          "Offensive Content",
          "Spam",
          "Other",
        ];
    }
  }

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;

    bool areArgsValid = false;
    if (arguments != null && arguments['reportType'] is ReportType) {
      reportType = arguments['reportType'] as ReportType;
      if (reportType == ReportType.user &&
          arguments['reportedUserId'] != null &&
          arguments['reportedUserName'] != null) {
        reportedItemId = arguments['reportedUserId'] as String;
        reportedItemTitle = arguments['reportedUserName'] as String;
        areArgsValid = true;
      } else if (reportType != ReportType.user &&
          arguments['reportedItemId'] != null &&
          arguments['reportedItemTitle'] != null) {
        reportedItemId = arguments['reportedItemId'] as String;
        reportedItemTitle = arguments['reportedItemTitle'] as String;
        areArgsValid = true;
      }
    }
    if (!areArgsValid) {
      LoggerService.logError(
        _className,
        'onInit',
        'Missing or invalid arguments for report submission.',
      );
      SnackbarService.showError(
        "Cannot submit report: Essential information is missing.",
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.key.currentState?.canPop() == true) {
          Navigator.of(Get.context!).pop();
        }
      });
    }
  }

  @override
  void onClose() {
    detailsController.dispose();
    super.onClose();
  }

  Future<void> submitReport() async {
    if (!(formKey.currentState?.validate() ?? false) ||
        (selectedReason.value == null || selectedReason.value!.isEmpty)) {
      SnackbarService.showWarning(
        title: "Incomplete",
        "Please select a reason for the report.",
      );
      return;
    }
    final currentUser = _authRepository.appUser.value;
    if (currentUser == null) {
      SnackbarService.showError("You need to be logged in to submit a report.");
      return;
    }
    isLoading.value = true;
    try {
      final withdrawnReport = await _reportRepository.findWithdrawnReport(
        reporterId: currentUser.userId,
        reportedId: reportedItemId,
        reportType: reportType,
      );
      if (withdrawnReport != null) {
        await _reportRepository.resubmitReport(
          reportId: withdrawnReport.id,
          reason: selectedReason.value!,
          details: detailsController.text.trim().isNotEmpty
              ? detailsController.text.trim()
              : null,
        );
        LoggerService.logInfo(
          _className,
          'submitReport',
          'Report ${withdrawnReport.id} re-submitted by ${currentUser.userId}',
        );
      } else {
        final report = ReportModel(
          id: '',
          reporterId: currentUser.userId,
          reportedId: reportedItemId,
          reportType: reportType,
          reason: selectedReason.value!,
          details: detailsController.text.trim().isNotEmpty
              ? detailsController.text.trim()
              : null,
          timestamp: DateTime.now(),
          status: ReportStatus.pending,
        );
        await _reportRepository.createReport(reportData: report);
        LoggerService.logInfo(
          _className,
          'submitReport',
          'New report for $reportedItemTitle submitted by ${currentUser.userId}',
        );
      }
      Get.back();
      SnackbarService.showSuccess(
        title: "Report Submitted",
        "Thank you! Your report for \"$reportedItemTitle\" has been received and will be reviewed.",
      );
    } catch (e) {
      LoggerService.logError(
        _className,
        'submitReport',
        'Error submitting report: $e',
      );
      SnackbarService.showError("Failed to submit report. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }
}
