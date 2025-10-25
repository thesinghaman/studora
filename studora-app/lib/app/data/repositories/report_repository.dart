import 'package:appwrite/models.dart' as appwrite_models;
import 'package:studora/app/data/models/report_model.dart';
import 'package:studora/app/data/providers/report_provider.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class ReportRepository {
  final ReportProvider _reportProvider;
  ReportRepository(this._reportProvider);

  Future<ReportModel> createReport({required ReportModel reportData}) async {
    const String className = 'ReportRepository';
    LoggerService.logInfo(
      className,
      'createReport',
      'Creating report for ${reportData.reportType.name}: ${reportData.reportedId}',
    );
    try {
      final appwrite_models.Document document = await _reportProvider
          .createReportDocument(
            data: reportData.toJson(),
            reporterId: reportData.reporterId,
          );
      return ReportModel.fromJson(document.data, document.$id);
    } catch (e, s) {
      LoggerService.logError(
        className,
        'createReport',
        'Failed to create report: $e',
        s,
      );
      rethrow;
    }
  }

  Future<ReportModel?> findExistingPendingReport({
    required String reporterId,
    required String reportedId,
    required ReportType type,
  }) async {
    const String className = 'ReportRepository';
    LoggerService.logInfo(
      className,
      'findExistingPendingReport',
      'Checking for existing report by $reporterId on $reportedId of type ${type.name}',
    );
    try {
      final appwrite_models.DocumentList response = await _reportProvider
          .findPendingReport(
            reporterId: reporterId,
            reportedId: reportedId,
            type: type.name,
          );
      if (response.documents.isNotEmpty) {
        final reportDocument = response.documents.first;
        LoggerService.logInfo(
          className,
          'findExistingPendingReport',
          'Found existing pending report: ${reportDocument.$id}',
        );
        return ReportModel.fromJson(reportDocument.data, reportDocument.$id);
      } else {
        LoggerService.logInfo(
          className,
          'findExistingPendingReport',
          'No existing pending report found.',
        );
        return null;
      }
    } catch (e, s) {
      LoggerService.logError(
        className,
        'findExistingPendingReport',
        'Database error: $e',
        s,
      );
      rethrow;
    }
  }

  Future<void> withdrawReport({required String reportId}) async {
    const String className = 'ReportRepository';
    LoggerService.logInfo(
      className,
      'withdrawReport',
      'Withdrawing report: $reportId',
    );
    try {
      await _reportProvider.updateReportStatus(
        reportId: reportId,
        status: ReportStatus.withdrawn.name,
      );
    } catch (e, s) {
      LoggerService.logError(
        className,
        'withdrawReport',
        'Failed to withdraw report: $e',
        s,
      );
      rethrow;
    }
  }
  Future<ReportModel> resubmitReport({
    required String reportId,
    required String reason,
    required String? details,
  }) async {
    const String className = 'ReportRepository';
    LoggerService.logInfo(
      className,
      'resubmitReport',
      'Re-submitting report: $reportId',
    );
    try {
      final data = {
        'reason': reason,
        'details': details,
        'status': ReportStatus.pending.name,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final document = await _reportProvider.resubmitReportDocument(
        reportId: reportId,
        data: data,
      );
      return ReportModel.fromJson(document.data, document.$id);
    } catch (e, s) {
      LoggerService.logError(
        className,
        'resubmitReport',
        'Failed to resubmit report: $e',
        s,
      );
      rethrow;
    }
  }
  Future<ReportModel?> findWithdrawnReport({
    required String reporterId,
    required String reportedId,
    required ReportType reportType,
  }) async {
    const String className = 'ReportRepository';
    LoggerService.logInfo(
      className,
      'findWithdrawnReport',
      'Checking for withdrawn report by $reporterId on $reportedId of type ${reportType.name}',
    );
    try {
      final appwrite_models.DocumentList response = await _reportProvider
          .findWithdrawnReport(
            reporterId: reporterId,
            reportedId: reportedId,
            type: reportType.name,
          );
      if (response.documents.isNotEmpty) {

        final reportDocument = response.documents.first;
        LoggerService.logInfo(
          className,
          'findWithdrawnReport',
          'Found withdrawn report: ${reportDocument.$id}',
        );
        return ReportModel.fromJson(reportDocument.data, reportDocument.$id);
      } else {

        LoggerService.logInfo(
          className,
          'findWithdrawnReport',
          'No withdrawn report found.',
        );
        return null;
      }
    } catch (e, s) {
      LoggerService.logError(
        className,
        'findWithdrawnReport',
        'Database error: $e',
        s,
      );
      rethrow;
    }
  }
}
