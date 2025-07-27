import 'package:get_storage/get_storage.dart';

import 'package:studora/app/services/logger_service.dart';

class StorageService {
  late final GetStorage _box;
  static const String _onboardingCompleteKey = 'onboardingComplete';

  static const String _recentSearchesKey = 'recent_searches';
  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    LoggerService.logInfo(
      "StorageService",
      "init",
      "Storage Service Initialized.",
    );
    return this;
  }

  bool isOnboardingComplete() {
    return _box.read<bool>(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _box.write(_onboardingCompleteKey, value);
  }

  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  Future<void> remove(String key) async {
    await _box.remove(key);
  }

  Future<void> clear() async {
    await _box.erase();
  }

  List<String> getRecentSearches() {
    return List<String>.from(
      _box.read<List<dynamic>>(_recentSearchesKey) ?? [],
    );
  }

  Future<void> saveRecentSearches(List<String> searches) async {
    await _box.write(_recentSearchesKey, searches);
  }
}
