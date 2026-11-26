import 'package:flutter/foundation.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/core/network/api_client.dart';
import 'package:ovision_app/core/storage/app_settings_storage.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    required AppSettingsStorage storage,
    required ApiClient apiClient,
  })  : _storage = storage,
        _apiClient = apiClient;

  final AppSettingsStorage _storage;
  final ApiClient _apiClient;

  String _baseUrl = AppConfig.defaultBaseUrl;
  bool _isLoading = true;
  bool _isTestingConnection = false;
  String? _connectionMessage;
  bool? _connectionOk;

  String get baseUrl => _baseUrl;
  bool get isLoading => _isLoading;
  bool get isTestingConnection => _isTestingConnection;
  String? get connectionMessage => _connectionMessage;
  bool? get connectionOk => _connectionOk;
  bool get isLocalhostConfigured => AppConfig.isLocalhostUrl(_baseUrl);

  Future<void> init() async {
    _baseUrl = await _storage.readBaseUrl();
    _apiClient.updateBaseUrl(_baseUrl);
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> saveBaseUrl(String rawUrl) async {
    final validationError = AppConfig.validateBaseUrl(rawUrl);
    if (validationError != null) {
      return validationError;
    }

    final normalized = AppConfig.normalizeBaseUrl(rawUrl);
    await _storage.saveBaseUrl(normalized);
    _baseUrl = normalized;
    _apiClient.updateBaseUrl(normalized);
    _connectionMessage = null;
    _connectionOk = null;
    notifyListeners();
    return null;
  }

  Future<void> testConnection(String rawUrl) async {
    final validationError = AppConfig.validateBaseUrl(rawUrl);
    if (validationError != null) {
      _connectionOk = false;
      _connectionMessage = validationError;
      notifyListeners();
      return;
    }

    _isTestingConnection = true;
    _connectionMessage = null;
    _connectionOk = null;
    notifyListeners();

    try {
      await _apiClient.testServerConnection(rawUrl);
      _connectionOk = true;
      _connectionMessage = 'Servidor Ovision alcançado com sucesso!';
    } on ApiException catch (e) {
      _connectionOk = false;
      _connectionMessage = e.message;
    } finally {
      _isTestingConnection = false;
      notifyListeners();
    }
  }

  void clearConnectionFeedback() {
    _connectionMessage = null;
    _connectionOk = null;
    notifyListeners();
  }
}
