import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/presentation/screens/server_settings_screen.dart';
import 'package:ovision_app/state/settings_provider.dart';

class ApiUrlBanner extends StatelessWidget {
  const ApiUrlBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isLocalhost = settings.isLocalhostConfigured;

    return Card(
      margin: EdgeInsets.zero,
      color: isLocalhost ? const Color(0xFFFFF8E1) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ServerSettingsScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isLocalhost ? Icons.warning_amber_rounded : Icons.dns_outlined,
                color: isLocalhost
                    ? const Color(0xFFB45309)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servidor da API',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      settings.baseUrl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isLocalhost) ...[
                      const SizedBox(height: 2),
                      Text(
                        '127.0.0.1/localhost aponta para o próprio celular. Toque para ajustar o IP do PC.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('Alterar'),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
