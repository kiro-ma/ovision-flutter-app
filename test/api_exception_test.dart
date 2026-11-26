import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ovision_app/core/errors/api_exception.dart';

void main() {
  group('ApiException.fromDioException', () {
    final req = RequestOptions(path: '/api/v1/inferences/');

    test('maps 422 no-animal response cleanly', () {
      final dioErr = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 422,
          data: {'detail': 'Nenhum animal com keypoints suficientes foi detectado.'},
        ),
      );
      final ex = ApiException.fromDioException(dioErr);
      expect(ex.type, ApiErrorType.unprocessable);
      expect(ex.statusCode, 422);
      expect(ex.message, contains('Nenhum animal'));
    });

    test('maps 400 DRF field validation errors', () {
      final dioErr = DioException(
        requestOptions: req,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: req,
          statusCode: 400,
          data: {
            'distance_cm': ['Certifique-se de que este valor seja maior ou igual a 10.0.'],
          },
        ),
      );
      final ex = ApiException.fromDioException(dioErr);
      expect(ex.type, ApiErrorType.validation);
      expect(ex.message, contains('Distância (cm)'));
    });

    test('maps connectionTimeout and connectionError to clear messages', () {
      final timeoutErr = DioException(
        requestOptions: req,
        type: DioExceptionType.connectionTimeout,
      );
      final netErr = DioException(
        requestOptions: req,
        type: DioExceptionType.connectionError,
      );

      expect(ApiException.fromDioException(timeoutErr).type, ApiErrorType.timeout);
      expect(ApiException.fromDioException(netErr).type, ApiErrorType.network);
    });
  });
}
