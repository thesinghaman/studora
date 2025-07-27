import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/data/models/item_model.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
import 'package:studora/app/services/logger_service.dart';
class ItemProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  static const String _className = 'ItemProvider';
  Future<List<appwrite_models.Document>> getItems({
    List<String>? queries,
    int? limit,
    int? offset,
  }) async {
    const String methodName = 'getItems';
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        queries: queries,
      );
      LoggerService.logInfo(
        _className,
        methodName,
        'Fetched ${response.documents.length} item documents.',
      );
      return response.documents;
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'AppwriteException fetching items: ${e.message}',
        s,
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Unknown exception fetching items: $e',
        s,
      );
      rethrow;
    }
  }

  Future<List<ItemModel>> getAllUserMarketplaceItems(String userId) async {
    const String methodName = 'getAllUserMarketplaceItems';
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        queries: [
          Query.equal('sellerId', userId),
          Query.equal('isRental', false),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return response.documents
          .map((doc) => ItemModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Appwrite Error: ${e.message}',
        s,
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(_className, methodName, 'Error: $e', s);
      rethrow;
    }
  }

  Future<List<ItemModel>> getAllUserRentalItems(String userId) async {
    const String methodName = 'getAllUserRentalItems';
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.itemsCollectionId,
        queries: [
          Query.equal('sellerId', userId),
          Query.equal('isRental', true),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return response.documents
          .map((doc) => ItemModel.fromJson(doc.data, doc.$id))
          .toList();
    } on AppwriteException catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Appwrite Error: ${e.message}',
        s,
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(_className, methodName, 'Error: $e', s);
      rethrow;
    }
  }
  Future<List<appwrite_models.Document>> getPublicFilteredItems(
    String itemType, {
    String? categoryId,
  }) async {
    try {

      final Map<String, dynamic> payload = {'listingType': itemType};
      if (categoryId != null) {
        payload['categoryId'] = categoryId;
      }
      final result = await _appwriteService.functions.createExecution(
        functionId: AppConstants.getPublicsListingsFunctionId,
        body: jsonEncode(payload),
      );
      if (result.responseStatusCode == 200) {
        final List<dynamic> responseData = jsonDecode(result.responseBody);
        return responseData
            .map((data) => appwrite_models.Document.fromMap(data))
            .toList();
      } else {
        throw Exception(
          'Failed to fetch filtered items: ${result.responseBody}',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'getPublicFilteredItems',
        'Error executing function for $itemType: $e',
        s,
      );
      rethrow;
    }
  }
  Future<List<appwrite_models.Document>> searchPublicFilteredItems({
    required String itemType,
    String? searchQuery,
    List<String>? categoryIds,
    int? limit,
    int? offset,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    String? collegeId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'listingType': itemType,
        if (searchQuery != null && searchQuery.isNotEmpty)
          'searchQuery': searchQuery,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categoryIds': categoryIds,
        if (collegeId != null) 'collegeId': collegeId,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (sortBy != null) 'sortBy': sortBy,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
      };
      final result = await _appwriteService.functions.createExecution(
        functionId: AppConstants.getPublicsListingsFunctionId,
        body: jsonEncode(payload),
      );
      if (result.responseStatusCode == 200) {
        final List<dynamic> responseData = jsonDecode(result.responseBody);
        return responseData
            .map((data) => appwrite_models.Document.fromMap(data))
            .toList();
      } else {
        throw Exception(
          'Failed to search filtered items: ${result.responseBody}',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        'searchPublicFilteredItems',
        'Error executing function for $itemType: $e',
        s,
      );
      rethrow;
    }
  }
}
