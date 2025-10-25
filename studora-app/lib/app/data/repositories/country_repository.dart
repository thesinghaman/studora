import 'dart:developer';
import 'package:appwrite/models.dart' as appwrite_models;
import 'package:get/get.dart';
import 'package:studora/app/data/models/country_model.dart';
import 'package:studora/app/data/providers/country_provider.dart';
class CountryRepository {
  final CountryProvider _countryProvider = Get.find<CountryProvider>();
  Future<List<CountryModel>> getActiveCountries() async {
    try {
      final List<appwrite_models.Document> documents = await _countryProvider
          .getActiveCountries();
      return documents
          .map((doc) => CountryModel.fromJson(doc.data, doc.$id))
          .toList();
    } catch (e) {
      log("Error in CountryRepository.getActiveCountries: $e");
      return [];
    }
  }
}
