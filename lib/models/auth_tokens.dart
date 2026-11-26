import 'package:ovision_app/models/farm.dart';

class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
  });

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: (json['access'] ?? '').toString(),
      refresh: (json['refresh'] ?? '').toString(),
    );
  }
}

class AuthResponse {
  const AuthResponse({
    required this.tokens,
    required this.farm,
  });

  final AuthTokens tokens;
  final Farm farm;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final rawFarm = json['farm'];
    return AuthResponse(
      tokens: AuthTokens.fromJson(json),
      farm: rawFarm is Map<String, dynamic>
          ? Farm.fromJson(rawFarm)
          : const Farm(
              id: '',
              name: '',
              ownerName: '',
              email: '',
              speciesFocus: 'caprinos',
            ),
    );
  }
}
