import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ovision_app/presentation/widgets/api_url_banner.dart';
import 'package:ovision_app/state/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _speciesFocusController = TextEditingController(text: 'caprinos');

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _ownerNameController.dispose();
    _speciesFocusController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();

    if (_isRegisterMode) {
      await auth.register(
        name: _farmNameController.text,
        ownerName: _ownerNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        speciesFocus: _speciesFocusController.text,
      );
    } else {
      await auth.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _fillDemoCredentials() {
    _emailController.text = 'demo@ovision.local';
    _passwordController.text = 'ovision123';
    context.read<AuthProvider>().clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: const Icon(Icons.agriculture, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ovision',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Biometria animal com YOLO Pose',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const ApiUrlBanner(),
                  const SizedBox(height: 16),
                  if (auth.sessionNotice != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auth.sessionNotice!,
                        style: const TextStyle(color: Color(0xFF92400E)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    margin: EdgeInsets.zero,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: false, label: Text('Entrar')),
                                ButtonSegment(value: true, label: Text('Criar conta')),
                              ],
                              selected: {_isRegisterMode},
                              onSelectionChanged: auth.isSubmitting
                                  ? null
                                  : (selection) {
                                      context.read<AuthProvider>().clearMessages();
                                      setState(() {
                                        _isRegisterMode = selection.first;
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),
                            if (_isRegisterMode) ...[
                              TextFormField(
                                controller: _farmNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nome da fazenda / criação',
                                  prefixIcon: Icon(Icons.home_work_outlined),
                                ),
                                validator: (value) {
                                  if (_isRegisterMode && (value == null || value.trim().isEmpty)) {
                                    return 'Informe o nome da fazenda.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _ownerNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Responsável',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (_isRegisterMode && (value == null || value.trim().isEmpty)) {
                                    return 'Informe o nome do responsável.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _speciesFocusController,
                                decoration: const InputDecoration(
                                  labelText: 'Espécie foco (ex.: caprinos)',
                                  prefixIcon: Icon(Icons.pets_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                hintText: 'demo@ovision.local',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty || !text.contains('@')) {
                                  return 'Informe um e-mail válido.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a senha.';
                                }
                                if (_isRegisterMode && value.length < 6) {
                                  return 'A senha deve ter ao menos 6 caracteres.';
                                }
                                return null;
                              },
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(color: Color(0xFFB71C1C)),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: auth.isSubmitting ? null : _submit,
                              child: auth.isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isRegisterMode ? 'Cadastrar e entrar' : 'Entrar'),
                            ),
                            if (!_isRegisterMode) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: auth.isSubmitting ? null : _fillDemoCredentials,
                                icon: const Icon(Icons.bolt, size: 18),
                                label: const Text('Usar conta demo (seed_farm)'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
