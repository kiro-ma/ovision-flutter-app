import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/presentation/screens/inference_detail_screen.dart';
import 'package:ovision_app/presentation/widgets/annotated_image_view.dart';
import 'package:ovision_app/presentation/widgets/measurement_grid.dart';
import 'package:ovision_app/services/media_picker_service.dart';
import 'package:ovision_app/state/inference_provider.dart';

class NewInferenceScreen extends StatefulWidget {
  const NewInferenceScreen({
    super.key,
    required this.mediaPickerService,
  });

  final MediaPickerService mediaPickerService;

  @override
  State<NewInferenceScreen> createState() => _NewInferenceScreenState();
}

class _NewInferenceScreenState extends State<NewInferenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _confController = TextEditingController();
  final _imgszController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _confController.dispose();
    _imgszController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(Future<PickedImageFile?> Function() pickerFn) async {
    try {
      final picked = await pickerFn();
      if (!mounted || picked == null) return;
      context.read<InferenceProvider>().setSelectedImage(picked);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Permissão negada ou recurso indisponível neste dispositivo.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível selecionar a imagem.'),
        ),
      );
    }
  }

  double? _parseOptionalDouble(String raw) {
    final clean = raw.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  int? _parseOptionalInt(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;
    return int.tryParse(clean);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<InferenceProvider>();
    final created = await provider.submitInference(
      distanceCm: _parseOptionalDouble(_distanceController.text),
      confThreshold: _parseOptionalDouble(_confController.text),
      imgsz: _parseOptionalInt(_imgszController.text),
    );

    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inferência concluída com sucesso!')),
      );
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InferenceProvider>();
    final theme = Theme.of(context);
    final selected = provider.selectedImage;
    final lastResult = provider.lastResult;
    final autoDist = selected != null
        ? AppConfig.extractDistanceFromFilename(selected.name)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '1. Capturar ou selecionar imagem',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fotografe o animal lateralmente ou selecione um arquivo salvo no aparelho.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: provider.isUploading
                              ? null
                              : () => _pickImage(widget.mediaPickerService.pickFromCamera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Tirar foto'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: provider.isUploading
                              ? null
                              : () => _pickImage(
                                    widget.mediaPickerService.pickFromFileExplorer,
                                  ),
                          icon: const Icon(Icons.folder_open_outlined),
                          label: const Text('Escolher arquivo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: provider.isUploading
                          ? null
                          : () => _pickImage(widget.mediaPickerService.pickFromGallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Abrir galeria'),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 220,
                        color: Colors.black12,
                        child: Image.file(
                          File(selected.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.sizeBytes != null
                                ? '${selected.name} (${_formatSize(selected.sizeBytes)})'
                                : selected.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover seleção',
                          onPressed: provider.isUploading ? null : provider.clearSelection,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    if (autoDist != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Distância detectada no nome do arquivo: ${autoDist.toStringAsFixed(0)} cm (usada se o campo abaixo ficar em branco).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '2. Parâmetros da captura',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _distanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distância câmera-animal em cm (opcional)',
                      hintText: 'Ex.: 160 (vazio = extrai do nome ou usa 160 cm)',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final parsed = _parseOptionalDouble(text);
                      if (parsed == null) {
                        return 'Informe um número válido em cm.';
                      }
                      if (parsed < 10.0 || parsed > 1000.0) {
                        return 'A distância deve ficar entre 10 e 1000 cm.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Parâmetros avançados (opcional)'),
                    childrenPadding: const EdgeInsets.only(top: 6, bottom: 8),
                    children: [
                      TextFormField(
                        controller: _confController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Confiança mínima (conf_threshold)',
                          hintText: 'Padrão da API: 0.25',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final parsed = _parseOptionalDouble(text);
                          if (parsed == null || parsed < 0.01 || parsed > 1.0) {
                            return 'Use um valor entre 0.01 e 1.0.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _imgszController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Resolução YOLO (imgsz)',
                          hintText: 'Padrão da API: 1280 (múltiplo de 32)',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return null;
                          final parsed = _parseOptionalInt(text);
                          if (parsed == null || parsed < 320 || parsed > 2560 || parsed % 32 != 0) {
                            return 'Use um múltiplo de 32 entre 320 e 2560.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  if (provider.uploadError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        provider.uploadError!,
                        style: const TextStyle(color: Color(0xFFB71C1C)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (provider.isUploading) ...[
                    LinearProgressIndicator(
                      value: (provider.uploadProgress != null && provider.uploadProgress! < 1.0)
                          ? provider.uploadProgress
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (provider.uploadProgress != null && provider.uploadProgress! < 1.0)
                          ? 'Enviando imagem (${(provider.uploadProgress! * 100).toStringAsFixed(0)}%)...'
                          : 'Processando pose e biometria no servidor...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton.icon(
                    onPressed: (selected == null || provider.isUploading) ? null : _submit,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(
                      provider.isUploading ? 'Processando inferência...' : 'Enviar para Inferência',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (lastResult != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resultado da Inferência',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InferenceDetailScreen(record: lastResult),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Detalhes'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnnotatedImageView(imageUrl: lastResult.imageUrl),
          const SizedBox(height: 14),
          MeasurementGrid(measurement: lastResult.measurement),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arquivo: ${lastResult.originalFilename}'),
                  Text('Distância usada: ${lastResult.distanceCm.toStringAsFixed(0)} cm'),
                  Text('Modelo: ${lastResult.modelTag}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
