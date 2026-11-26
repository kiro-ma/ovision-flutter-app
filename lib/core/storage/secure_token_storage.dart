import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ovision_app/models/auth_tokens.dart';
import 'package:ovision_app/models/farm.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _accessKey = 'ovision_access_token';
  static const String _refreshKey = 'ovision_refresh_token';
  static const String _farmKey = 'ovision_farm_profile';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required AuthTokens tokens,
    Farm? farm,
  }) async {
    await _storage.write(key: _accessKey, value: tokens.access);
    await _storage.write(key: _refreshKey, value: tokens.refresh);
    if (farm != null) {
      await _storage.write(key: _farmKey, value: jsonEncode(farm.toJson()));
    }
  }

  Future<void> updateAccessToken(String access, {String? refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> saveFarm(Farm farm) async {
    await _storage.write(key: _farmKey, value: jsonEncode(farm.toJson()));
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<Farm?> readCachedFarm() async {
    final raw = await _storage.read(key: _farmKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return Farm.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _farmKey);
  }
}
