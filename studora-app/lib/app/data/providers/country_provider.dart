import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class CountryProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  Future<List<appwrite_models.Document>> getActiveCountries() async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.countriesCollectionId,
        queries: [
          Query.equal('isActive', [true]),
          Query.orderAsc('name'),
        ],
      );
      return response.documents;
    } on AppwriteException catch (e) {
      LoggerService.logError(
        "CountryProvider, AppwriteException",
        "getActiveCountries",
        e,
      );
      rethrow;
    } catch (e) {
      LoggerService.logError("CountryProvider", "getActiveCountries", e);
      rethrow;
    }
  }
}
