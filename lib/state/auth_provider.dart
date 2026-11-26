import 'package:flutter/foundation.dart';

import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/models/farm.dart';
import 'package:ovision_app/repositories/auth_repository.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository}) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initializing;
  Farm? _farm;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _sessionNotice;

  AuthStatus get status => _status;
  Farm? get farm => _farm;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get sessionNotice => _sessionNotice;

  Future<void> init() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    final restored = await _authRepository.restoreSession();
    if (restored != null) {
      _farm = restored;
      _status = AuthStatus.authenticated;
    } else {
      _farm = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _sessionNotice = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(email: email, password: password);
      _farm = result.farm;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String ownerName,
    required String email,
    required String password,
    String speciesFocus = 'caprinos',
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _sessionNotice = null;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        name: name,
        ownerName: ownerName,
        email: email,
        password: password,
        speciesFocus: speciesFocus,
      );
      _farm = result.farm;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      _farm = await _authRepository.getProfile();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.unauthorized) {
        handleSessionExpired();
      }
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _farm = null;
    _errorMessage = null;
    _sessionNotice = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void handleSessionExpired() {
    _farm = null;
    _errorMessage = null;
    _sessionNotice = 'Sua sessão expirou. Faça login novamente para continuar.';
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _sessionNotice = null;
    notifyListeners();
  }
}
