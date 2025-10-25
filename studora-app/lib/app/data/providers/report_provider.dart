import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/shared_components/utils/enums.dart';
class ReportProvider {
  final Databases _databases;
  ReportProvider(AppwriteService appwriteService)
    : _databases = appwriteService.databases;
  Future<appwrite_models.Document> createReportDocument({
    required Map<String, dynamic> data,
    required String reporterId,
  }) {
    return _databases.createDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.reportsCollectionId,
      documentId: ID.unique(),
      data: data,
      permissions: [
        Permission.read(Role.user(reporterId)),
        Permission.update(Role.user(reporterId)),
      ],
    );
  }
  Future<appwrite_models.Document> updateReportStatus({
    required String reportId,
    required String status,
  }) {
    return _databases.updateDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.reportsCollectionId,
      documentId: reportId,
      data: {'status': status},
    );
  }
  Future<appwrite_models.DocumentList> findPendingReport({
    required String reporterId,
    required String reportedId,
    required String type,
  }) {
    return _databases.listDocuments(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.reportsCollectionId,
      queries: [
        Query.equal('reporterId', reporterId),
        Query.equal('reportedId', reportedId),
        Query.equal('reportType', type),
        Query.equal('status', ['pending']),
        Query.limit(1),
      ],
    );
  }
  Future<appwrite_models.DocumentList> findWithdrawnReport({
    required String reporterId,
    required String reportedId,
    required String type,
  }) {
    return _databases.listDocuments(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.reportsCollectionId,
      queries: [
        Query.equal('reporterId', reporterId),
        Query.equal('reportedId', reportedId),
        Query.equal('reportType', type),
        Query.equal('status', [ReportStatus.withdrawn.name]),
        Query.limit(1),
      ],
    );
  }
  Future<appwrite_models.Document> resubmitReportDocument({
    required String reportId,
    required Map<String, dynamic> data,
  }) {
    return _databases.updateDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.reportsCollectionId,
      documentId: reportId,
      data: data,
    );
  }
}
