import 'dart:developer';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/data/models/college_model.dart';
import 'package:studora/app/data/providers/college_provider.dart';
class CollegeRepository {
  final CollegeProvider _collegeProvider = Get.find<CollegeProvider>();
  Future<List<CollegeModel>> getActiveColleges() async {
    try {
      final List<appwrite_models.Document> documents = await _collegeProvider
          .getActiveColleges();
      return documents
          .map((doc) => CollegeModel.fromJson(doc.data, doc.$id))
          .toList();
    } catch (e) {
      log("Error in CollegeRepository.getActiveColleges: $e");
      return [];
    }
  }
  Future<CollegeModel?> getCollegeById(String collegeId) async {
    try {
      final appwrite_models.Document doc = await _collegeProvider.getCollege(
        collegeId,
      );
      return CollegeModel.fromJson(doc.data, doc.$id);
    } catch (e) {
      log("Error in CollegeRepository.getCollegeById: $e");
      return null;
    }
  }
}
