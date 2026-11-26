import 'package:shared_preferences/shared_preferences.dart';

import 'package:ovision_app/core/config/app_config.dart';

class AppSettingsStorage {
  static const String _apiBaseUrlKey = 'ovision_api_base_url';

  Future<String> readBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_apiBaseUrlKey);
    if (stored == null || stored.trim().isEmpty) {
      return AppConfig.defaultBaseUrl;
    }
    final normalized = AppConfig.normalizeBaseUrl(stored);
    return normalized.isEmpty ? AppConfig.defaultBaseUrl : normalized;
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, AppConfig.normalizeBaseUrl(baseUrl));
  }
}
