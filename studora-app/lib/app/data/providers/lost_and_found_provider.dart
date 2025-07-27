import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studora/app/data/models/lost_found_item_model.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class LostAndFoundProvider extends GetxService {
  static const String _className = 'LostAndFoundProvider';
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  Databases get _databases => _appwriteService.databases;
  Storage get storage => _appwriteService.storage;
  Future<LostFoundItemModel> createLostFoundItem(
    LostFoundItemModel item,
  ) async {
    const String functionName = 'createLostFoundItem';
    try {
      final document = await _databases.createDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        documentId: ID.unique(),
        data: item.toJson(),
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(item.reporterId)),
          Permission.delete(Role.user(item.reporterId)),
        ],
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Lost/Found item created: ${document.$id}',
      );
      return LostFoundItemModel.fromAppwriteDocument(document);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error creating item: $e',
        s,
      );
      throw Exception('Failed to create Lost & Found item: ${e.toString()}');
    }
  }

  Future<List<LostFoundItemModel>> getAllUserLostAndFoundItems(
    String userId,
  ) async {
    const String methodName = 'getAllUserLostAndFoundItems';
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        queries: [
          Query.equal('reporterId', userId),
          Query.orderDesc('\$createdAt'),
        ],
      );
      return response.documents
          .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
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
  Future<List<LostFoundItemModel>> getLostFoundItems({
    List<String>? queries,
    int? limit,
    int? offset,
  }) async {
    const String functionName = 'getLostFoundItems';
    try {
      List<String> defaultQueries = [
        Query.equal('isActive', true),
        Query.orderDesc('dateReported'),
      ];
      if (queries != null) {
        defaultQueries.addAll(queries);
      }
      if (limit != null) defaultQueries.add(Query.limit(limit));
      if (offset != null) defaultQueries.add(Query.offset(offset));
      final response = await _databases.listDocuments(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        queries: defaultQueries,
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Fetched ${response.documents.length} items.',
      );
      return response.documents
          .map((doc) => LostFoundItemModel.fromAppwriteDocument(doc))
          .toList();
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error fetching items: $e',
        s,
      );
      throw Exception('Failed to fetch Lost & Found items: ${e.toString()}');
    }
  }
  Future<LostFoundItemModel> getLostFoundItemById(String itemId) async {
    const String functionName = 'getLostFoundItemById';
    try {
      final document = await _databases.getDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        documentId: itemId,
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Fetched item: ${document.$id}',
      );
      return LostFoundItemModel.fromAppwriteDocument(document);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error fetching item $itemId: $e',
        s,
      );
      throw Exception(
        'Failed to fetch Lost & Found item details: ${e.toString()}',
      );
    }
  }
  Future<LostFoundItemModel> updateLostFoundItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    const String functionName = 'updateLostFoundItem';
    try {
      final document = await _databases.updateDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        documentId: itemId,
        data: data,
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Item updated: ${document.$id}',
      );
      return LostFoundItemModel.fromAppwriteDocument(document);
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error updating item $itemId: $e',
        s,
      );
      throw Exception('Failed to update Lost & Found item: ${e.toString()}');
    }
  }
  Future<void> permanentlyDeleteItemDocument(String itemId) async {
    const String functionName = 'permanentlyDeleteItemDocument';
    try {
      await _databases.deleteDocument(
        databaseId: AppConstants.appwriteDatabaseId,
        collectionId: AppConstants.lostFoundItemsCollectionId,
        documentId: itemId,
      );
      LoggerService.logInfo(
        _className,
        functionName,
        'Item permanently deleted: $itemId',
      );
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error permanently deleting item $itemId: $e',
        s,
      );
      throw Exception(
        'Failed to permanently delete Lost & Found item document: ${e.toString()}',
      );
    }
  }
  Future<List<String>> uploadImagesToBucket(
    List<XFile> imageFiles,
    String bucketId,
  ) async {
    const String functionName = 'uploadImagesToBucket';
    List<String> uploadedImageUrls = [];
    try {
      for (XFile imageFile in imageFiles) {
        final file = InputFile.fromPath(
          path: imageFile.path,
          filename: imageFile.name,
        );
        final response = await storage.createFile(
          bucketId: bucketId,
          fileId: ID.unique(),
          file: file,
          permissions: [Permission.read(Role.any())],
        );
        final imageUrl =
            '${AppwriteService.projectEndpoint}/storage/buckets/$bucketId/files/${response.$id}/view?project=${AppwriteService.projectId}';
        uploadedImageUrls.add(imageUrl);
        LoggerService.logInfo(
          _className,
          functionName,
          'Uploaded image: ${response.$id}, URL: $imageUrl',
        );
      }
      return uploadedImageUrls;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error uploading images: $e',
        s,
      );
      throw Exception('Failed to upload images: ${e.toString()}');
    }
  }
  Future<void> deleteImagesFromBucket(
    List<String> fileIds,
    String bucketId,
  ) async {
    const String functionName = 'deleteImagesFromBucket';
    try {
      for (String fileId in fileIds) {
        await storage.deleteFile(bucketId: bucketId, fileId: fileId);
        LoggerService.logInfo(
          _className,
          functionName,
          'Deleted image file: $fileId from bucket: $bucketId',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error deleting images from bucket $bucketId: $e',
        s,
      );
    }
  }
  Future<List<appwrite_models.Document>> getPublicFilteredLfItems(
    String lfType,
    String? collegeId, {
    List<String>? categoryIds,
    int? limit,
    int? offset,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    const String functionName = 'getPublicFilteredLfItems';
    try {
      final Map<String, dynamic> payload = {
        'listingType': lfType,
        if (collegeId != null) 'collegeId': collegeId,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categoryIds': categoryIds,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
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
          'Failed to fetch filtered L&F items: ${result.responseBody}',
        );
      }
    } catch (e, s) {
      LoggerService.logError(
        _className,
        functionName,
        'Error executing function for $lfType: $e',
        s,
      );
      rethrow;
    }
  }
}
