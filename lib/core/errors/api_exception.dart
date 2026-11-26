import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  validation,
  unprocessable,
  server,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;

  @override
  String toString() => message;

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message:
              'Tempo esgotado ao conectar ao servidor. Verifique se o celular e o PC estão na mesma rede Wi-Fi e se a URL/porta da API estão corretas.',
        );
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message:
              'O servidor demorou mais que o esperado para responder à inferência. Tente novamente.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.network,
          message:
              'Não foi possível alcançar o servidor da API. Confirme o IP da máquina na rede local e se o Django está rodando com 0.0.0.0.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'Requisição cancelada.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'Certificado HTTPS inválido para o endereço informado.',
        );
      case DioExceptionType.unknown:
        return const ApiException(
          type: ApiErrorType.network,
          message:
              'Falha de rede ao comunicar com a API. Verifique sua conexão e o endereço configurado.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? detail;
    Map<String, List<String>>? parsedFields;

    if (data is Map) {
      final rawDetail = data['detail'];
      if (rawDetail is String && rawDetail.trim().isNotEmpty) {
        detail = rawDetail.trim();
      } else if (rawDetail is List && rawDetail.isNotEmpty) {
        detail = rawDetail.map((e) => e.toString()).join(' ');
      }

      final fields = <String, List<String>>{};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        if (key == 'detail') continue;
        final val = entry.value;
        if (val is List) {
          fields[key] = val.map((e) => e.toString()).toList();
        } else if (val is String && val.trim().isNotEmpty) {
          fields[key] = [val.trim()];
        }
      }
      if (fields.isNotEmpty) {
        parsedFields = fields;
        detail ??= fields.entries
            .map((e) => '${_humanizeField(e.key)}: ${e.value.join(", ")}')
            .join('\n');
      }
    } else if (data is String && data.trim().isNotEmpty && !data.trim().startsWith('<')) {
      detail = data.trim();
    }

    if (statusCode == 401) {
      return ApiException(
        type: ApiErrorType.unauthorized,
        statusCode: statusCode,
        fieldErrors: parsedFields,
        message: detail ?? 'Credenciais inválidas ou sessão expirada. Faça login novamente.',
      );
    }
    if (statusCode == 422) {
      return ApiException(
        type: ApiErrorType.unprocessable,
        statusCode: statusCode,
        fieldErrors: parsedFields,
        message: detail ??
            'Nenhum animal com pontos anatômicos suficientes foi detectado na imagem enviada.',
      );
    }
    if (statusCode == 400) {
      return ApiException(
        type: ApiErrorType.validation,
        statusCode: statusCode,
        fieldErrors: parsedFields,
        message: detail ?? 'Dados inválidos enviados para a API.',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        type: ApiErrorType.server,
        statusCode: statusCode,
        message: detail ?? 'Erro interno no servidor Django (HTTP $statusCode).',
      );
    }

    return ApiException(
      type: ApiErrorType.unknown,
      statusCode: statusCode,
      fieldErrors: parsedFields,
      message: detail ?? 'Resposta inesperada do servidor (HTTP ${statusCode ?? "?"}).',
    );
  }

  static String _humanizeField(String key) {
    switch (key) {
      case 'email':
        return 'E-mail';
      case 'password':
        return 'Senha';
      case 'name':
        return 'Nome da fazenda';
      case 'owner_name':
        return 'Responsável';
      case 'distance_cm':
        return 'Distância (cm)';
      case 'conf_threshold':
        return 'Confiança';
      case 'imgsz':
        return 'Resolução';
      case 'file':
      case 'image':
        return 'Imagem';
      case 'non_field_errors':
        return 'Validação';
      default:
        return key;
    }
  }
}
