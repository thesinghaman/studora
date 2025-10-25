import 'dart:developer';
import 'package:get/get.dart';
import 'package:studora/app/data/models/legal_document_model.dart';
import 'package:studora/app/data/repositories/legal_document_repository.dart';
enum LegalDocType { terms, privacy }
class LegalDocumentController extends GetxController {
  final LegalDocType docType;
  LegalDocumentController({required this.docType});
  final LegalDocumentRepository _repository =
      Get.find<LegalDocumentRepository>();
  var isLoading = true.obs;
  var legalDocument = Rxn<LegalDocumentModel>();
  var errorMessage = RxnString();
  @override
  void onInit() {
    super.onInit();
    fetchDocument();
  }
  Future<void> fetchDocument() async {
    try {
      isLoading(true);
      errorMessage.value = null;
      if (docType == LegalDocType.terms) {
        legalDocument.value = await _repository.getTermsAndConditions();
      } else {
        legalDocument.value = await _repository.getPrivacyPolicy();
      }
      if (legalDocument.value == null) {
        errorMessage.value = "Document not found or failed to load.";
      }
    } catch (e) {
      errorMessage.value = "An error occurred: ${e.toString()}";
      log("Error fetching legal document: $e");
    } finally {
      isLoading(false);
    }
  }
}
