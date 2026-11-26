import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/state/settings_provider.dart';

class AnnotatedImageView extends StatefulWidget {
  const AnnotatedImageView({
    super.key,
    required this.imageUrl,
    this.height = 260,
    this.enableZoomTap = true,
  });

  final String imageUrl;
  final double height;
  final bool enableZoomTap;

  @override
  State<AnnotatedImageView> createState() => _AnnotatedImageViewState();
}

class _AnnotatedImageViewState extends State<AnnotatedImageView> {
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final baseUrl = context.watch<SettingsProvider>().baseUrl;
    final resolvedUrl = AppConfig.resolveMediaUrl(baseUrl, widget.imageUrl);
    final theme = Theme.of(context);

    if (resolvedUrl.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('URL da imagem inferida indisponível.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.black87,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: widget.enableZoomTap
                  ? () => _openFullscreen(context, resolvedUrl)
                  : null,
              child: Image.network(
                resolvedUrl,
                key: ValueKey('$_reloadKey-$resolvedUrl'),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  final expected = loadingProgress.expectedTotalBytes;
                  final loaded = loadingProgress.cumulativeBytesLoaded;
                  final progress = expected != null && expected > 0
                      ? loaded / expected
                      : null;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(value: progress),
                        const SizedBox(height: 10),
                        const Text(
                          'Carregando imagem anotada...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Não foi possível carregar a imagem da API.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resolvedUrl,
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36),
                            ),
                            onPressed: () {
                              setState(() {
                                _reloadKey++;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.enableZoomTap)
              Positioned(
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Ampliar',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFullscreen(BuildContext context, String url) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Imagem Inferida'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5.0,
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
