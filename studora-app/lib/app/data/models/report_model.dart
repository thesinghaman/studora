import 'package:studora/app/shared_components/utils/enums.dart';
class ReportModel {
  final String id;
  final String reporterId;
  final String reportedId;
  final ReportType reportType;
  final String reason;
  final String? details;
  final DateTime timestamp;
  ReportStatus status;
  final String? adminNotes;
  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reportType,
    required this.reason,
    this.details,
    required this.timestamp,
    this.status = ReportStatus.pending,
    this.adminNotes,
  });
  factory ReportModel.fromJson(Map<String, dynamic> json, String documentId) {
    ReportType rType;
    switch (json['reportType'] as String?) {
      case 'user':
        rType = ReportType.user;
        break;
      case 'item':
        rType = ReportType.item;
        break;
      case 'lostFoundItem':
        rType = ReportType.lostFoundItem;
        break;
      default:
        rType = ReportType.item;
    }
    ReportStatus rStatus;
    switch (json['status'] as String?) {
      case 'pending':
        rStatus = ReportStatus.pending;
        break;
      case 'reviewed':
        rStatus = ReportStatus.reviewed;
        break;
      case 'resolved':
        rStatus = ReportStatus.resolved;
        break;
      case 'dismissed':
        rStatus = ReportStatus.dismissed;
        break;
      default:
        rStatus = ReportStatus.pending;
    }
    return ReportModel(
      id: documentId,
      reporterId: json['reporterId'] as String,
      reportedId: json['reportedId'] as String,
      reportType: rType,
      reason: json['reason'] as String? ?? 'No reason provided',
      details: json['details'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String? ?? '') ??
                DateTime.now()
          : DateTime.now(),
      status: rStatus,
      adminNotes: json['adminNotes'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reportType': reportType.toString().split('.').last,
      'reason': reason,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'adminNotes': adminNotes,
    };
  }
}
