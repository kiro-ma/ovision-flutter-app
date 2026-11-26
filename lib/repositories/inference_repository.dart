import 'package:dio/dio.dart';

import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/core/network/api_client.dart';
import 'package:ovision_app/models/inference_record.dart';

class InferenceRepository {
  InferenceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<InferenceRecord> createInference({
    required String filePath,
    required String filename,
    double? distanceCm,
    double? confThreshold,
    int? imgsz,
    ProgressCallback? onSendProgress,
  }) async {
    Future<Response<Map<String, dynamic>>> sendMultipart() async {
      final map = <String, dynamic>{
        'image': await MultipartFile.fromFile(filePath, filename: filename),
      };
      if (distanceCm != null) {
        map['distance_cm'] = distanceCm.toString();
      }
      if (confThreshold != null) {
        map['conf_threshold'] = confThreshold.toString();
      }
      if (imgsz != null) {
        map['imgsz'] = imgsz.toString();
      }

      final formData = FormData.fromMap(map);
      return _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/inferences/',
        data: formData,
        onSendProgress: onSendProgress,
      );
    }

    try {
      final response = await sendMultipart();
      return InferenceRecord.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _apiClient.refreshAccessToken();
        if (refreshed) {
          try {
            final retryResponse = await sendMultipart();
            return InferenceRecord.fromJson(retryResponse.data ?? <String, dynamic>{});
          } on DioException catch (retryErr) {
            throw ApiException.fromDioException(retryErr);
          }
        }
      }
      throw ApiException.fromDioException(e);
    }
  }

  Future<InferenceListResponse> listInferences() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/v1/inferences/');
      return InferenceListResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<InferenceRecord> getInferenceDetail(String id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/api/v1/inferences/$id/');
      return InferenceRecord.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
