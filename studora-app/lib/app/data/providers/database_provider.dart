import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/services/logger_service.dart';
class DatabaseProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  static const String _className = 'DatabaseProvider';
  Future<appwrite_models.Document> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
    List<String>? permissions,
  }) async {
    const String methodName = 'createDocument';
    try {
      return await _appwriteService.databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
        permissions: permissions,
      );
    } on AppwriteException catch (e) {
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown exception: $e",
        s,
      );
      rethrow;
    }
  }
  Future<appwrite_models.Document?> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    const String methodName = 'getDocument';
    try {
      return await _appwriteService.databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        LoggerService.logWarning(
          _className,
          methodName,
          "Document $documentId not found in $collectionId. ${e.message}",
        );
        return null;
      }
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown exception: $e",
        s,
      );
      rethrow;
    }
  }
  Future<appwrite_models.Document> updateDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
    List<String>? permissions,
  }) async {
    const String methodName = 'updateDocument';
    try {
      return await _appwriteService.databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
        permissions: permissions,
      );
    } on AppwriteException catch (e) {
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException updating document $documentId: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown exception updating document $documentId: $e",
        s,
      );
      rethrow;
    }
  }

  Future<appwrite_models.DocumentList> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    const String methodName = 'listDocuments';
    try {
      return await _appwriteService.databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries,
      );
    } on AppwriteException catch (e) {
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException listing documents: ${e.message}",
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown exception listing documents: $e",
        s,
      );
      rethrow;
    }
  }
  Future<void> deleteAppwriteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    const String methodName = 'deleteAppwriteDocument';
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
      LoggerService.logInfo(
        _className,
        methodName,
        "Document $documentId deleted successfully from $collectionId.",
      );
    } on AppwriteException catch (e) {
      LoggerService.logError(
        _className,
        methodName,
        "AppwriteException deleting document $documentId: ${e.message} (Code: ${e.code})",
      );
      rethrow;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        "Unknown exception deleting document $documentId: $e",
        s,
      );
      rethrow;
    }
  }
}
