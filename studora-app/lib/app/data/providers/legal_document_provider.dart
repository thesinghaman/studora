import 'dart:developer';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class LegalDocumentProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  Future<appwrite_models.Document?> getLegalDocument(String docType) async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.legalDocumentsCollectionId,
        queries: [Query.equal('docType', docType), Query.limit(1)],
      );
      if (response.documents.isNotEmpty) {
        return response.documents.first;
      }
      return null;
    } on AppwriteException catch (e) {
      log(
        "AppwriteException in LegalDocumentProvider.getLegalDocument for $docType: ${e.message}",
      );
      rethrow;
    } catch (e) {
      log(
        "Unknown exception in LegalDocumentProvider.getLegalDocument for $docType: $e",
      );
      rethrow;
    }
  }
}
