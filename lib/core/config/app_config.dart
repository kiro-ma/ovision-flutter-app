class AppConfig {
  AppConfig._();

  static const String defaultBaseUrl = 'http://192.168.0.100:8000';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration sendTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 90);

  static final RegExp _distanceFilenameRegex = RegExp(r'dist(\d+)');

  /// Normaliza a URL base removendo espaços e barras finais, adicionando http:// quando ausente.
  static String normalizeBaseUrl(String raw) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Valida se a URL informada é válida para comunicação HTTP/HTTPS com o servidor Django.
  static String? validateBaseUrl(String raw) {
    final normalized = normalizeBaseUrl(raw);
    if (normalized.isEmpty) {
      return 'Informe a URL do servidor da API.';
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Use um endereço iniciado por http:// ou https://.';
    }
    if (uri.host.isEmpty) {
      return 'Informe o IP ou domínio do servidor (ex.: http://192.168.0.100:8000).';
    }
    if (uri.hasPort && (uri.port <= 0 || uri.port > 65535)) {
      return 'Porta inválida na URL informada.';
    }
    return null;
  }

  /// Indica se o endereço aponta para loopback local (que falha em aparelho físico em campo).
  static bool isLocalhostUrl(String raw) {
    final uri = Uri.tryParse(normalizeBaseUrl(raw));
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == '127.0.0.1' || host == 'localhost';
  }

  /// Resolve a URL da imagem anotada retornada pela API, preservando o host configurado na rede local.
  static String resolveMediaUrl(String baseUrl, String rawImageUrl) {
    final trimmedImage = rawImageUrl.trim();
    if (trimmedImage.isEmpty) {
      return '';
    }
    final baseNormalized = normalizeBaseUrl(baseUrl);
    final baseUri = Uri.tryParse(baseNormalized);
    final imageUri = Uri.tryParse(trimmedImage);

    if (imageUri == null) {
      return trimmedImage;
    }

    if (!imageUri.hasScheme) {
      if (baseUri == null) return trimmedImage;
      final path = trimmedImage.startsWith('/') ? trimmedImage : '/$trimmedImage';
      return '$baseNormalized$path';
    }

    if (baseUri != null &&
        (imageUri.host == '127.0.0.1' || imageUri.host == 'localhost') &&
        baseUri.host.isNotEmpty &&
        baseUri.host != imageUri.host) {
      return imageUri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          )
          .toString();
    }

    return trimmedImage;
  }

  /// Espelha a heurística do backend (`dist<cm>`) para informar o usuário ao selecionar um arquivo.
  static double? extractDistanceFromFilename(String filename) {
    final match = _distanceFilenameRegex.firstMatch(filename);
    if (match == null) return null;
    return double.tryParse(match.group(1) ?? '');
  }
}
