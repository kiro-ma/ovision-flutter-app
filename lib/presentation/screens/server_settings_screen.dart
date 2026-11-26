import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/core/config/app_config.dart';
import 'package:ovision_app/state/settings_provider.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _urlController = TextEditingController(text: settings.baseUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SettingsProvider>().clearConnectionFeedback();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.read<SettingsProvider>().testConnection(_urlController.text);
  }

  Future<void> _saveUrl() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final settings = context.read<SettingsProvider>();
    final err = await settings.saveBaseUrl(_urlController.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL salva: ${settings.baseUrl}')),
    );
    Navigator.of(context).pop();
  }

  void _applyPreset(String url) {
    _urlController.text = url;
    context.read<SettingsProvider>().clearConnectionFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Servidor da API'),
      ),
      body: SafeArea(
        child: ListView(
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
                        'Endereço base do backend Django',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Para testar no celular físico na mesma rede Wi-Fi, informe o IP da sua máquina na rede local (ex.: http://192.168.0.100:8000).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'URL da API',
                          hintText: 'http://192.168.0.100:8000',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) => AppConfig.validateBaseUrl(value ?? ''),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('LAN :8000'),
                            onPressed: () => _applyPreset('http://192.168.0.100:8000'),
                          ),
                          ActionChip(
                            label: const Text('LAN :8009'),
                            onPressed: () => _applyPreset('http://192.168.0.100:8009'),
                          ),
                          ActionChip(
                            label: const Text('Emulador Android'),
                            onPressed: () => _applyPreset('http://10.0.2.2:8000'),
                          ),
                        ],
                      ),
                      if (settings.connectionMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: settings.connectionOk == true
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                settings.connectionOk == true
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: settings.connectionOk == true
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  settings.connectionMessage!,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: settings.isTestingConnection ? null : _testConnection,
                        icon: settings.isTestingConnection
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: Text(
                          settings.isTestingConnection
                              ? 'Testando conexão...'
                              : 'Testar conexão',
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: settings.isTestingConnection ? null : _saveUrl,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar URL da API'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                      'Dicas rápidas para testes em campo (LAN)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. No PC, descubra o IPv4 da rede Wi-Fi com ipconfig (Windows) ou ip addr (Linux).\n'
                      '2. Inicie o Django escutando na rede:\n'
                      '   python manage.py runserver 0.0.0.0:8000\n'
                      '3. Não use 127.0.0.1 em celular físico: no aparelho, 127.0.0.1 aponta para o próprio telefone.\n'
                      '4. Se não conectar, libere a porta 8000 (ou 8009) no Firewall do Windows.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
