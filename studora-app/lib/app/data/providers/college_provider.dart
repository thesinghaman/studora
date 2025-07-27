import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class CollegeProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  Future<List<appwrite_models.Document>> getActiveColleges() async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.collegesCollectionId,
        queries: [
          Query.equal('isActive', true),
          Query.orderAsc('name'),
        ],
      );
      return response.documents;
    } on AppwriteException catch (e) {
      LoggerService.logError(
        "CollegeProvider, AppwriteException",
        "getActiveColleges",
        e,
      );
      rethrow;
    } catch (e) {
      LoggerService.logError("CollegeProvider", "getActiveColleges", e);
      rethrow;
    }
  }

  Future<appwrite_models.Document> getCollege(String collegeId) async {
    try {
      return await _appwriteService.databases.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.collegesCollectionId,
        documentId: collegeId,
      );
    } on AppwriteException catch (e) {
      LoggerService.logError(
        "CollegeProvider, AppwriteException",
        "getCollege",
        e,
      );
      rethrow;
    } catch (e) {
      LoggerService.logError("CollegeProvider", "getCollege", e);
      rethrow;
    }
  }
}
