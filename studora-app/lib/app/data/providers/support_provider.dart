import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:studora/app/data/repositories/auth_repository.dart';
import 'package:studora/app/services/appwrite_service.dart';
import 'package:studora/app/shared_components/utils/app_constants.dart';
class SupportProvider {
  final AppwriteService _appwriteService = Get.find<AppwriteService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  Future<void> createSupportTicket(Map<String, dynamic> data) async {
    final userId = _authRepository.appUser.value?.userId;
    if (userId == null) throw Exception("User not authenticated.");
    await _appwriteService.databases.createDocument(
      databaseId: AppConstants.appwriteDatabaseId,
      collectionId: AppConstants.supportTicketsCollectionId,
      documentId: ID.unique(),
      data: data,
      permissions: [
        Permission.read(Role.user(userId)),
        Permission.update(Role.user(userId)),
        Permission.delete(Role.user(userId)),
      ],
    );
  }
}
