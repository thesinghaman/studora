import 'dart:developer';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/data/models/legal_document_model.dart';
import 'package:studora/app/data/providers/legal_document_provider.dart';
class LegalDocumentRepository {
  final LegalDocumentProvider _provider = Get.find<LegalDocumentProvider>();
  Future<LegalDocumentModel?> getTermsAndConditions() async {
    return _getFormattedDocument("termsAndConditions");
  }
  Future<LegalDocumentModel?> getPrivacyPolicy() async {
    return _getFormattedDocument("privacyPolicy");
  }
  Future<LegalDocumentModel?> _getFormattedDocument(String docType) async {
    try {
      final appwrite_models.Document? document = await _provider
          .getLegalDocument(docType);
      if (document != null) {
        return LegalDocumentModel.fromJson(document.data, document.$id);
      }
      return null;
    } catch (e) {
      log(
        "Error in LegalDocumentRepository._getFormattedDocument for $docType: $e",
      );
      return null;
    }
  }
}
