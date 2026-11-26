import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/models/inference_record.dart';
import 'package:ovision_app/presentation/widgets/annotated_image_view.dart';
import 'package:ovision_app/presentation/widgets/measurement_grid.dart';
import 'package:ovision_app/state/inference_provider.dart';

class InferenceDetailScreen extends StatefulWidget {
  const InferenceDetailScreen({
    super.key,
    required this.record,
  });

  final InferenceRecord record;

  @override
  State<InferenceDetailScreen> createState() => _InferenceDetailScreenState();
}

class _InferenceDetailScreenState extends State<InferenceDetailScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  late InferenceRecord _record;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _refreshDetail() async {
    setState(() {
      _refreshing = true;
    });
    final updated = await context.read<InferenceProvider>().fetchDetail(_record.id);
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      if (updated != null) {
        _record = updated;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kptCount = _record.measurement?.rawKeypoints?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Inferência'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _refreshing ? null : _refreshDetail,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AnnotatedImageView(imageUrl: _record.imageUrl, height: 280),
          const SizedBox(height: 16),
          MeasurementGrid(measurement: _record.measurement),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metadados da Análise',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20),
                  _InfoRow(label: 'Arquivo original', value: _record.originalFilename),
                  _InfoRow(
                    label: 'Data / Hora',
                    value: _dateFormat.format(_record.createdAt.toLocal()),
                  ),
                  _InfoRow(
                    label: 'Distância',
                    value: '${_record.distanceCm.toStringAsFixed(1)} cm',
                  ),
                  _InfoRow(label: 'Modelo / Pesos', value: _record.modelTag),
                  _InfoRow(
                    label: 'Confiança / imgsz',
                    value: '${_record.confThreshold} / ${_record.imgsz}px',
                  ),
                  _InfoRow(label: 'Keypoints detectados', value: '$kptCount pontos'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
