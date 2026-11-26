import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/presentation/screens/inference_detail_screen.dart';
import 'package:ovision_app/state/inference_provider.dart';
import 'package:ovision_app/state/settings_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InferenceProvider>().loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InferenceProvider>();
    final baseUrl = context.watch<SettingsProvider>().baseUrl;
    final theme = Theme.of(context);

    if (provider.isLoadingHistory && provider.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.historyError != null && provider.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                provider.historyError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: provider.loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.history.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.history_toggle_off, size: 56),
            SizedBox(height: 12),
            Text(
              'Nenhuma inferência registrada para esta fazenda ainda.\nEnvie uma foto na aba Nova Inferência.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final record = provider.history[index];
          final thumbUrl = AppConfig.resolveMediaUrl(baseUrl, record.imageUrl);
          final peso = record.measurement?.pesoKg;
          final cernelha = record.measurement?.alturaCernelha;

          return Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InferenceDetailScreen(record: record),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 78,
                        height: 78,
                        color: Colors.black12,
                        child: thumbUrl.isEmpty
                            ? const Icon(Icons.image_not_supported_outlined)
                            : Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.originalFilename,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Peso: ${peso != null ? "${peso.toStringAsFixed(2)} kg" : "--"}  •  '
                            'Cernelha: ${cernelha != null ? "${cernelha.toStringAsFixed(1)} cm" : "--"}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_dateFormat.format(record.createdAt.toLocal())} • Dist: ${record.distanceCm.toStringAsFixed(0)} cm',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
