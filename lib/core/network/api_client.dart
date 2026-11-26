import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/core/storage/secure_token_storage.dart';

class ApiClient {
  ApiClient({
    required SecureTokenStorage tokenStorage,
    String initialBaseUrl = AppConfig.defaultBaseUrl,
    VoidCallback? onSessionExpired,
  })  : _tokenStorage = tokenStorage,
        _onSessionExpired = onSessionExpired,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.normalizeBaseUrl(initialBaseUrl),
            connectTimeout: AppConfig.connectTimeout,
            sendTimeout: AppConfig.sendTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: _handleRequest,
        onError: _handleError,
      ),
    );
  }

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  VoidCallback? _onSessionExpired;
  Completer<bool>? _refreshCompleter;

  static const Set<String> _publicAuthPaths = {
    '/api/v1/auth/token/',
    '/api/v1/auth/token/refresh/',
    '/api/v1/auth/register/',
  };

  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setSessionExpiredCallback(VoidCallback? callback) {
    _onSessionExpired = callback;
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = AppConfig.normalizeBaseUrl(newBaseUrl);
  }

  Future<void> _handleRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final access = await _tokenStorage.readAccessToken();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;
    final options = error.requestOptions;

    final alreadyRetried = options.extra['retried'] == true;
    final isPublicAuth = _isPublicAuthPath(options.path);
    // FormData finalizados pelo Dio não podem ser reutilizados em retry direto no interceptor;
    // uploads multipart renovam o token e reconstroem o FormData no repositório.
    final isMultipart = options.data is FormData;

    if (statusCode == 401 && !alreadyRetried && !isPublicAuth && !isMultipart) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newAccess = await _tokenStorage.readAccessToken();
        if (newAccess != null && newAccess.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $newAccess';
          options.extra['retried'] = true;
          try {
            final retryResponse = await _dio.fetch<dynamic>(options);
            return handler.resolve(retryResponse);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }
      }
    }

    handler.next(error);
  }

  bool _isPublicAuthPath(String path) {
    return _publicAuthPaths.any((p) => path.endsWith(p));
  }

  /// Renova o access token usando o refresh token armazenado de forma sincronizada.
  Future<bool> refreshAccessToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.connectTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      final data = response.data;
      final newAccess = data?['access'] as String?;
      final newRefresh = data?['refresh'] as String?;

      if (newAccess != null && newAccess.isNotEmpty) {
        await _tokenStorage.updateAccessToken(newAccess, refresh: newRefresh);
        completer.complete(true);
        return true;
      }

      await _expireSession();
      completer.complete(false);
      return false;
    } on DioException catch (err) {
      final status = err.response?.statusCode;
      if (status == 401 || status == 400) {
        await _expireSession();
      }
      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clearSession();
    _onSessionExpired?.call();
  }

  /// Verifica se o endereço informado responde na rede local.
  Future<void> testServerConnection(String candidateBaseUrl) async {
    final normalized = AppConfig.normalizeBaseUrl(candidateBaseUrl);
    final testDio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    try {
      await testDio.get<dynamic>('/api/v1/auth/me/');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
