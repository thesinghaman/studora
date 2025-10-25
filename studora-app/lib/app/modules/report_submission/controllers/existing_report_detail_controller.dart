import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:studora/app/data/models/report_model.dart';
import 'package:studora/app/data/repositories/report_repository.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/snackbar_service.dart';

class ExistingReportDetailController extends GetxController {
  final ReportRepository _reportRepository = Get.find<ReportRepository>();
  late final ReportModel report;
  var isWithdrawing = false.obs;
  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments == null ||
        arguments['report'] == null ||
        arguments['report'] is! ReportModel) {
      Get.back();
      return;
    }
    report = arguments['report'] as ReportModel;
  }

  void confirmWithdrawal() {
    Get.defaultDialog(
      title: "Confirm Withdrawal",
      middleText:
          "Are you sure you want to withdraw this report? This action cannot be undone.",
      textConfirm: "Withdraw",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: _withdrawReport,
    );
  }

  Future<void> _withdrawReport() async {
    if (Get.isDialogOpen ?? false) Get.back();
    isWithdrawing.value = true;
    try {
      await _reportRepository.withdrawReport(reportId: report.id);

      Get.back(result: true);
      SnackbarService.showSuccess(
        "Your report has been successfully withdrawn.",
      );
    } catch (e) {
      LoggerService.logError(
        'ExistingReportDetailController',
        '_withdrawReport',
        'Error: $e',
      );
      SnackbarService.showError("Failed to withdraw report. Please try again.");
    } finally {
      isWithdrawing.value = false;
    }
  }
}
