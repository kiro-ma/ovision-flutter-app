import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/presentation/screens/history_screen.dart';
import 'package:ovision_app/presentation/screens/new_inference_screen.dart';
import 'package:ovision_app/presentation/screens/server_settings_screen.dart';
import 'package:ovision_app/services/media_picker_service.dart';
import 'package:ovision_app/state/auth_provider.dart';
import 'package:ovision_app/state/inference_provider.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.mediaPickerService,
  });

  final MediaPickerService mediaPickerService;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    context.read<InferenceProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final farm = context.watch<AuthProvider>().farm;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              farm?.name.isNotEmpty == true ? farm!.name : 'Ovision',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              farm != null ? 'Foco: ${farm.speciesFocus}' : 'Biometria Animal IA',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Configurar URL da API',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ServerSettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.dns_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          NewInferenceScreen(mediaPickerService: widget.mediaPickerService),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            context.read<InferenceProvider>().loadHistory();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Nova Inferência',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
