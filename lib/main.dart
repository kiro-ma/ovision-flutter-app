import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/core/network/api_client.dart';
import 'package:ovision_app/core/storage/app_settings_storage.dart';
import 'package:ovision_app/core/storage/secure_token_storage.dart';
import 'package:ovision_app/core/theme/app_theme.dart';
import 'package:ovision_app/presentation/screens/home_shell_screen.dart';
import 'package:ovision_app/presentation/screens/login_screen.dart';
import 'package:ovision_app/repositories/auth_repository.dart';
import 'package:ovision_app/repositories/inference_repository.dart';
import 'package:ovision_app/services/media_picker_service.dart';
import 'package:ovision_app/state/auth_provider.dart';
import 'package:ovision_app/state/inference_provider.dart';
import 'package:ovision_app/state/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsStorage = AppSettingsStorage();
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
  final inferenceRepository = InferenceRepository(apiClient: apiClient);
  final mediaPickerService = MediaPickerService();

  final settingsProvider = SettingsProvider(storage: settingsStorage, apiClient: apiClient);
  final authProvider = AuthProvider(authRepository: authRepository);
  final inferenceProvider = InferenceProvider(repository: inferenceRepository);

  apiClient.setSessionExpiredCallback(() {
    inferenceProvider.reset();
    authProvider.handleSessionExpired();
  });

  runApp(
    OvisionApp(
      settingsProvider: settingsProvider,
      authProvider: authProvider,
      inferenceProvider: inferenceProvider,
      mediaPickerService: mediaPickerService,
    ),
  );
}

class OvisionApp extends StatefulWidget {
  const OvisionApp({
    super.key,
    required this.settingsProvider,
    required this.authProvider,
    required this.inferenceProvider,
    required this.mediaPickerService,
  });

  final SettingsProvider settingsProvider;
  final AuthProvider authProvider;
  final InferenceProvider inferenceProvider;
  final MediaPickerService mediaPickerService;

  @override
  State<OvisionApp> createState() => _OvisionAppState();
}

class _OvisionAppState extends State<OvisionApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await widget.settingsProvider.init();
    await widget.authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsProvider),
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.inferenceProvider),
      ],
      child: MaterialApp(
        title: 'Ovision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            switch (auth.status) {
              case AuthStatus.initializing:
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('Carregando Ovision...'),
                      ],
                    ),
                  ),
                );
              case AuthStatus.authenticated:
                return HomeShellScreen(mediaPickerService: widget.mediaPickerService);
              case AuthStatus.unauthenticated:
                return const LoginScreen();
            }
          },
        ),
      ),
    );
  }
}
