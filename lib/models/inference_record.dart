import 'package:ovision_app/models/biometric_measurement.dart';

class InferenceRecord {
  const InferenceRecord({
    required this.id,
    required this.farmId,
    this.animalId,
    required this.originalFilename,
    required this.imageUrl,
    required this.distanceCm,
    required this.modelTag,
    required this.confThreshold,
    required this.imgsz,
    required this.createdAt,
    this.measurement,
  });

  final String id;
  final String farmId;
  final String? animalId;
  final String originalFilename;
  final String imageUrl;
  final double distanceCm;
  final String modelTag;
  final double confThreshold;
  final int imgsz;
  final DateTime createdAt;
  final BiometricMeasurement? measurement;

  factory InferenceRecord.fromJson(Map<String, dynamic> json) {
    final rawMeasurement = json['measurement'];
    return InferenceRecord(
      id: (json['id'] ?? '').toString(),
      farmId: (json['farm_id'] ?? '').toString(),
      animalId: json['animal_id']?.toString(),
      originalFilename: (json['original_filename'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      distanceCm: (json['distance_cm'] as num?)?.toDouble() ?? 160.0,
      modelTag: (json['model_tag'] ?? '').toString(),
      confThreshold: (json['conf_threshold'] as num?)?.toDouble() ?? 0.25,
      imgsz: (json['imgsz'] as num?)?.toInt() ?? 1280,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
      measurement: rawMeasurement is Map<String, dynamic>
          ? BiometricMeasurement.fromJson(rawMeasurement)
          : (rawMeasurement is Map
              ? BiometricMeasurement.fromJson(Map<String, dynamic>.from(rawMeasurement))
              : null),
    );
  }
}

class InferenceListResponse {
  const InferenceListResponse({
    required this.count,
    required this.results,
  });

  final int count;
  final List<InferenceRecord> results;

  factory InferenceListResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final items = rawResults is List
        ? rawResults
            .whereType<Map>()
            .map((item) => InferenceRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <InferenceRecord>[];
    return InferenceListResponse(
      count: (json['count'] as num?)?.toInt() ?? items.length,
      results: items,
    );
  }
}
