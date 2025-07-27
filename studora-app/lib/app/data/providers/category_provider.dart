import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/services/logger_service.dart';
class CategoryProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  static const String _className = 'CategoryProvider';
  Databases get _databases => _appwriteService.databases;
  Future<List<appwrite_models.Document>> getCategories({String? type}) async {
    const String functionName = 'getCategories';
    try {
      List<String> queries = [
        Query.equal('isActive', true),
        Query.orderAsc('name'),
      ];
      if (type != null && type.isNotEmpty) {
        queries.add(Query.equal('type', type));
      }
      final response = await _databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.categoriesCollectionId,
        queries: queries,
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Fetched ${response.documents.length} categories for type: $type',
      );
      return response.documents;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error fetching categories for type $type: $e',
        s,
      );
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }
  Future<Map<String, dynamic>?> getCategory(String categoryId) async {
    try {
      final document = await _appwriteService.databases.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.categoriesCollectionId,
        documentId: categoryId,
      );
      return document.data;
    } catch (e) {

      return null;
    }
  }
}
