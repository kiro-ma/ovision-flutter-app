import 'package:dio/dio.dart';

import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/core/network/api_client.dart';
import 'package:ovision_app/core/storage/secure_token_storage.dart';
import 'package:ovision_app/models/auth_tokens.dart';
import 'package:ovision_app/models/farm.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/token/',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final auth = AuthResponse.fromJson(data);
      await _tokenStorage.saveSession(tokens: auth.tokens, farm: auth.farm);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String ownerName,
    required String email,
    required String password,
    String speciesFocus = 'caprinos',
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register/',
        data: {
          'name': name.trim(),
          'owner_name': ownerName.trim(),
          'email': email.trim(),
          'password': password,
          'species_focus': speciesFocus.trim().isEmpty ? 'caprinos' : speciesFocus.trim(),
        },
      );
      final data = response.data ?? <String, dynamic>{};
      final auth = AuthResponse.fromJson(data);
      await _tokenStorage.saveSession(tokens: auth.tokens, farm: auth.farm);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Farm> getProfile() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/v1/auth/me/');
      final farm = Farm.fromJson(response.data ?? <String, dynamic>{});
      await _tokenStorage.saveFarm(farm);
      return farm;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Restaura a sessão salva no aparelho. Se o token access expirou, o ApiClient renova automaticamente.
  Future<Farm?> restoreSession() async {
    final access = await _tokenStorage.readAccessToken();
    final refresh = await _tokenStorage.readRefreshToken();
    if ((access == null || access.isEmpty) && (refresh == null || refresh.isEmpty)) {
      return null;
    }

    try {
      return await getProfile();
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        await _tokenStorage.clearSession();
        return null;
      }
      // Se estiver offline no momento da abertura, reaproveita os dados locais em cache.
      return _tokenStorage.readCachedFarm();
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearSession();
  }
}
