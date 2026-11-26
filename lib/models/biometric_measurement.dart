class KeypointPoint {
  const KeypointPoint({
    required this.index,
    required this.name,
    required this.x,
    required this.y,
    required this.conf,
  });

  final int index;
  final String name;
  final double x;
  final double y;
  final double conf;

  factory KeypointPoint.fromJson(Map<String, dynamic> json) {
    return KeypointPoint(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      conf: (json['conf'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BiometricMeasurement {
  const BiometricMeasurement({
    required this.id,
    this.pesoKg,
    this.alturaCernelha,
    this.alturaGarupa,
    this.comprimento,
    this.circTorax,
    this.grossuraPescoco,
    this.rawKeypoints,
  });

  final String id;
  final double? pesoKg;
  final double? alturaCernelha;
  final double? alturaGarupa;
  final double? comprimento;
  final double? circTorax;
  final double? grossuraPescoco;
  final List<KeypointPoint>? rawKeypoints;

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  factory BiometricMeasurement.fromJson(Map<String, dynamic> json) {
    final rawKpts = json['raw_keypoints'];
    List<KeypointPoint>? keypoints;
    if (rawKpts is List) {
      keypoints = rawKpts
          .whereType<Map>()
          .map((item) => KeypointPoint.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return BiometricMeasurement(
      id: (json['id'] ?? '').toString(),
      pesoKg: _toDouble(json['peso_kg']),
      alturaCernelha: _toDouble(json['altura_cernelha']),
      alturaGarupa: _toDouble(json['altura_garupa']),
      comprimento: _toDouble(json['comprimento']),
      circTorax: _toDouble(json['circ_torax']),
      grossuraPescoco: _toDouble(json['grossura_pescoco']),
      rawKeypoints: keypoints,
    );
  }
}
