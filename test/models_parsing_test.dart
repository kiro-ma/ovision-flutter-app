import 'package:flutter_test/flutter_test.dart';

import 'package:ovision_app/models/auth_tokens.dart';
import 'package:ovision_app/models/inference_record.dart';

void main() {
  group('API JSON parsing', () {
    test('parses AuthResponse from POST /api/v1/auth/token/', () {
      final json = {
        'access': 'jwt-access-123',
        'refresh': 'jwt-refresh-456',
        'farm': {
          'id': '34a33770-ad25-44af-a648-c9e2487da66a',
          'name': 'Fazenda Ovision Demo',
          'owner_name': 'Produtor Demo',
          'email': 'demo@ovision.local',
          'species_focus': 'caprinos',
          'created_at': '2026-11-25T22:00:00-03:00',
        },
      };

      final auth = AuthResponse.fromJson(json);
      expect(auth.tokens.access, 'jwt-access-123');
      expect(auth.tokens.refresh, 'jwt-refresh-456');
      expect(auth.farm.id, '34a33770-ad25-44af-a648-c9e2487da66a');
      expect(auth.farm.name, 'Fazenda Ovision Demo');
      expect(auth.farm.ownerName, 'Produtor Demo');
      expect(auth.farm.email, 'demo@ovision.local');
      expect(auth.farm.speciesFocus, 'caprinos');
      expect(auth.farm.createdAt, isNotNull);
    });

    test('parses InferenceListResponse and BiometricMeasurement', () {
      final json = {
        'count': 1,
        'results': [
          {
            'id': 'a56058b2-57f8-44b5-be51-f52a3ff39e98',
            'farm_id': '34a33770-ad25-44af-a648-c9e2487da66a',
            'animal_id': null,
            'original_filename': '010-dist160-v3.jpg',
            'image_url': 'http://192.168.0.100:8000/media/inferences/demo.jpg',
            'distance_cm': 160.0,
            'model_tag': 'caprine-bovidae-v4-strict-clean (strict-clean)',
            'conf_threshold': 0.25,
            'imgsz': 1280,
            'created_at': '2026-11-25T22:17:40-03:00',
            'measurement': {
              'id': '9f3b1111-2222-3333-4444-555566667777',
              'peso_kg': 52.09,
              'altura_cernelha': 72.6,
              'altura_garupa': 70.6,
              'comprimento': 65.8,
              'circ_torax': 92.6,
              'grossura_pescoco': 27.1,
              'raw_keypoints': [
                {'index': 0, 'name': 'left_eye', 'x': 120.5, 'y': 220.0, 'conf': 0.99},
              ],
            },
          },
        ],
      };

      final list = InferenceListResponse.fromJson(json);
      expect(list.count, 1);
      expect(list.results, hasLength(1));

      final record = list.results.first;
      expect(record.animalId, isNull);
      expect(record.originalFilename, '010-dist160-v3.jpg');
      expect(record.distanceCm, 160.0);
      expect(record.imgsz, 1280);

      final m = record.measurement;
      expect(m, isNotNull);
      expect(m!.pesoKg, 52.09);
      expect(m.alturaCernelha, 72.6);
      expect(m.alturaGarupa, 70.6);
      expect(m.comprimento, 65.8);
      expect(m.circTorax, 92.6);
      expect(m.grossuraPescoco, 27.1);
      expect(m.rawKeypoints, hasLength(1));
      expect(m.rawKeypoints!.first.name, 'left_eye');
    });
  });
}
