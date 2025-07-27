import 'package:get/get.dart';
import 'package:studora/app/data/models/category_model.dart';
import 'package:studora/app/data/providers/category_provider.dart';
import 'package:studora/app/services/logger_service.dart';
class CategoryRepository {
  final CategoryProvider _categoryProvider = Get.find<CategoryProvider>();
  static const String _className = 'CategoryRepository';
  Future<List<CategoryModel>> getCategories({String? type}) async {
    const String methodName = 'getCategories';
    try {
      final documents = await _categoryProvider.getCategories(type: type);
      List<CategoryModel> categories = documents
          .map((doc) => CategoryModel.fromJson(doc.data, doc.$id))
          .toList();
      LoggerService.logInfo(
        _className,
        methodName,
        'Mapped ${categories.length} categories for type: $type.',
      );
      return categories;
    } catch (e, s) {
      LoggerService.logError(
        _className,
        methodName,
        'Error fetching categories for type $type: $e',
        s,
      );
      return [];
    }
  }
  Future<CategoryModel?> getCategoryById(String categoryId) async {
    try {
      final categoryData = await _categoryProvider.getCategory(categoryId);
      if (categoryData != null) {
        return CategoryModel.fromJson(categoryData, categoryId);
      }
      return null;
    } catch (e) {
      LoggerService.logError(
        _className,
        "Error fetching category by ID: $categoryId",
        e.toString(),
      );
      return null;
    }
  }
}
