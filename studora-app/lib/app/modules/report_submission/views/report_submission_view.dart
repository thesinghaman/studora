import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:get/get.dart';

import 'package:studora/app/modules/report_submission/controllers/report_submission_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class ReportSubmissionView extends GetView<ReportSubmissionController> {
  const ReportSubmissionView({super.key});
  String _getReportTypeDisplayString(ReportType type) {
    switch (type) {
      case ReportType.item:
        return "Ad/Item";
      case ReportType.user:
        return "User";
      case ReportType.lostFoundItem:
        return "Lost & Found Post";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report ${_getReportTypeDisplayString(controller.reportType)}",
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        surfaceTintColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "You are reporting:",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.reportedItemTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                "Reason for reporting*",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedReason.value,
                  items: controller.reportReasons.map((String reason) {
                    return DropdownMenuItem<String>(
                      value: reason,
                      child: Text(reason, style: theme.textTheme.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    controller.selectedReason.value = newValue;
                  },
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please select a reason'
                      : null,
                  decoration: InputDecoration(
                    hintText: "Select a reason",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1.2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  isExpanded: true,
                  icon: Icon(
                    CupertinoIcons.chevron_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                "Additional Details (Optional)",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.detailsController,
                maxLines: 4,
                maxLength: 500,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: "Provide more information if necessary...",
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(radius: 15),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            CupertinoIcons.paperplane_fill,
                            size: 20,
                          ),
                          label: const Text("Submit Report"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: controller.submitReport,
                        ),
                      ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Text(
                  "All reports are treated confidentially.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
