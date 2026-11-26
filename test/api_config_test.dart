import 'package:flutter_test/flutter_test.dart';

import 'package:ovision_app/core/config/app_config.dart';

void main() {
  group('AppConfig URL & distance helpers', () {
    test('normalizes and validates base URLs', () {
      expect(
        AppConfig.normalizeBaseUrl(' 192.168.0.15:8000/ '),
        'http://192.168.0.15:8000',
      );
      expect(
        AppConfig.validateBaseUrl('http://192.168.0.15:8000'),
        isNull,
      );
      expect(
        AppConfig.validateBaseUrl(''),
        isNotNull,
      );
      expect(AppConfig.isLocalhostUrl('http://127.0.0.1:8000'), isTrue);
      expect(AppConfig.isLocalhostUrl('http://192.168.0.15:8000'), isFalse);
    });

    test('resolves relative media URL and rewrites loopback host to LAN host', () {
      expect(
        AppConfig.resolveMediaUrl(
          'http://192.168.0.15:8000',
          '/media/inferences/pose.jpg',
        ),
        'http://192.168.0.15:8000/media/inferences/pose.jpg',
      );
      expect(
        AppConfig.resolveMediaUrl(
          'http://192.168.0.15:8009',
          'http://127.0.0.1:8009/media/inferences/pose.jpg',
        ),
        'http://192.168.0.15:8009/media/inferences/pose.jpg',
      );
    });

    test('extracts camera distance from filename pattern dist<cm>', () {
      expect(AppConfig.extractDistanceFromFilename('010-dist160-v3.jpg'), 160.0);
      expect(AppConfig.extractDistanceFromFilename('caprino_dist200.png'), 200.0);
      expect(AppConfig.extractDistanceFromFilename('foto_campo.jpg'), isNull);
    });
  });
}
