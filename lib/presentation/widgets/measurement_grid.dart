import 'package:flutter/material.dart';

import 'package:ovision_app/models/biometric_measurement.dart';

class MeasurementGrid extends StatelessWidget {
  const MeasurementGrid({
    super.key,
    required this.measurement,
  });

  final BiometricMeasurement? measurement;

  String _formatValue(double? value, String unit, {int decimals = 1}) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    if (m == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhuma medição biométrica associada a este registro.'),
        ),
      );
    }

    final theme = Theme.of(context);
    final metrics = [
      _MetricItem(
        label: 'Alt. Cernelha',
        value: _formatValue(m.alturaCernelha, 'cm'),
        icon: Icons.height,
      ),
      _MetricItem(
        label: 'Alt. Garupa',
        value: _formatValue(m.alturaGarupa, 'cm'),
        icon: Icons.straighten,
      ),
      _MetricItem(
        label: 'Comprimento',
        value: _formatValue(m.comprimento, 'cm'),
        icon: Icons.swap_horiz,
      ),
      _MetricItem(
        label: 'Circ. Torácica',
        value: _formatValue(m.circTorax, 'cm'),
        icon: Icons.trip_origin,
      ),
      _MetricItem(
        label: 'Gross. Pescoço',
        value: _formatValue(m.grossuraPescoco, 'cm'),
        icon: Icons.adjust,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Icon(Icons.monitor_weight_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PESO VIVO ESTIMADO',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatValue(m.pesoKg, 'kg', decimals: 2),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics.map((metric) {
                return SizedBox(
                  width: itemWidth > 120 ? itemWidth : constraints.maxWidth,
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            metric.icon,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  metric.value,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
