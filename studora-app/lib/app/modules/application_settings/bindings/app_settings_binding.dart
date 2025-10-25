import 'package:get/get.dart';
import 'package:studora/app/data/providers/legal_document_provider.dart';
import 'package:studora/app/data/repositories/legal_document_repository.dart';
class AppSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LegalDocumentProvider>(() => LegalDocumentProvider());
    Get.lazyPut<LegalDocumentRepository>(() => LegalDocumentRepository());
  }
}
