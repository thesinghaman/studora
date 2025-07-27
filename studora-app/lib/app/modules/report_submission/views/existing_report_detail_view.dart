import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:studora/app/modules/report_submission/controllers/existing_report_detail_controller.dart';
import 'package:studora/app/shared_components/utils/enums.dart';

class ExistingReportDetailView extends GetView<ExistingReportDetailController> {
  const ExistingReportDetailView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Status'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(theme),
                const SizedBox(height: 24),
                _buildDetailSection(
                  theme: theme,
                  icon: Icons.flag_outlined,
                  title: 'Reason for Report',
                  content:
                      controller.report.reason.capitalizeFirst ??
                      controller.report.reason,
                ),
                const SizedBox(height: 24),
                _buildDetailSection(
                  theme: theme,
                  icon: Icons.comment_outlined,
                  title: 'Your Comments',
                  content: controller.report.details?.isNotEmpty == true
                      ? controller.report.details!
                      : 'No comments were provided.',
                ),
                const SizedBox(height: 24),
                _buildDetailSection(
                  theme: theme,
                  icon: Icons.calendar_today_outlined,
                  title: 'Date Submitted',
                  content: DateFormat(
                    'd MMMM, yyyy \'at\' h:mm a',
                  ).format(controller.report.timestamp),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Our team is reviewing your report. Thank you for helping us keep the community safe.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() {
                  if (controller.report.status == ReportStatus.pending) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: controller.isWithdrawing.value
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text("Withdraw Report"),
                                onPressed: controller.confirmWithdrawal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainer,
                                  foregroundColor:
                                      theme.colorScheme.onSurfaceVariant,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    IconData statusIcon;
    Color statusColor;
    String statusText =
        controller.report.status.name.capitalizeFirst ??
        controller.report.status.name;
    switch (controller.report.status) {
      case ReportStatus.pending:
        statusIcon = Icons.hourglass_top_rounded;
        statusColor = Colors.orange.shade700;
        break;
      case ReportStatus.reviewed:
        statusIcon = Icons.visibility_outlined;
        statusColor = Colors.blue.shade700;
        statusText = 'Under Review';
        break;
      case ReportStatus.resolved:
        statusIcon = Icons.check_circle_outline_rounded;
        statusColor = Colors.green.shade700;
        break;
      case ReportStatus.dismissed:
        statusIcon = Icons.do_not_disturb_on_outlined;
        statusColor = theme.colorScheme.error;
        break;

      case ReportStatus.withdrawn:
        statusIcon = Icons.undo_rounded;
        statusColor = Colors.grey.shade600;
        statusText = 'Withdrawn by You';
        break;
    }
    return Card(
      elevation: 0,
      color: statusColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Status', style: theme.textTheme.labelLarge),
                  Text(
                    statusText,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.hintColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
