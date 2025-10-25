import 'package:get/get.dart';
import 'package:studora/app/data/providers/support_provider.dart';
class SupportRepository {
  final SupportProvider _provider = Get.put(SupportProvider());
  Future<void> submitSupportTicket({
    required String userId,
    required String userEmail,
    required String category,
    required String subject,
    required String message,
  }) {
    return _provider.createSupportTicket({
      'userId': userId,
      'userEmail': userEmail,
      'category': category,
      'subject': subject,
      'message': message,
      'status': 'open',
    });
  }
}
