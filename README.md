# Ovision App (Flutter — Fase 1)

Aplicativo móvel base em **Flutter** para a Fase 1 do projeto **Ovision**, integrado à API REST + JWT em [`../ovision-ai-api`](../ovision-ai-api) para captura em campo na rede local.

---

## Funcionalidades Implementadas (Fase 1)

* **Configuração rápida da URL da API (LAN):**
  * Alteração da URL base do backend (`http://<IP-DO-PC>:8000`, `:8009`, etc.) direto na tela de login ou pela barra superior após logado, com teste de conectividade e persistência local via `SharedPreferences`.
* **Autenticação JWT (`POST /api/v1/auth/token/`, `register/`, `token/refresh/`, `me/`):**
  * Login da fazenda por e-mail e senha (com botão rápido para preencher a conta demo `demo@ovision.local` / `ovision123` criada via `seed_farm`).
  * Cadastro de nova fazenda e persistência segura dos tokens (`flutter_secure_storage`) com renovação automática do `access` token via `refresh` token.
* **Nova Inferência (`POST /api/v1/inferences/`):**
  * **Tirar foto** diretamente pela câmera do dispositivo (`image_picker`).
  * **Escolher arquivo** no explorador de arquivos do aparelho (`file_picker`, preservando nomes como `010-dist160-v3.jpg`) ou abrir a galeria.
  * Pré-visualização da imagem selecionada, campo opcional de `distance_cm` (aceitando `,` ou `.`), opções avançadas (`conf_threshold`, `imgsz`), envio `multipart/form-data` com barra de progresso e exibição imediata da imagem anotada (`image_url`) com zoom + medidas biométricas (`peso_kg`, `altura_cernelha`, `altura_garupa`, `comprimento`, `circ_torax`, `grossura_pescoco`).
* **Histórico da Fazenda (`GET /api/v1/inferences/` e `GET /api/v1/inferences/<uuid>/`):**
  * Listagem com pull-to-refresh e tela de detalhe completo com visualização ampliável da imagem inferida.

> **Escopo Fase 2:** os modelos estruturais `HerdRef` e `AnimalRef` estão reservados em `lib/models/phase2_placeholders.dart`, sem CRUD de rebanhos/animais nesta etapa.

---

## Estrutura de Pastas

```text
lib/
  core/
    config/app_config.dart             # URL padrão, timeouts, resolução de image_url e regex dist<cm>
    errors/api_exception.dart          # Tratamento de erros de rede, timeout, 400, 401 e 422
    network/api_client.dart            # Dio + QueuedInterceptor JWT + refresh automático + teste LAN
    storage/app_settings_storage.dart  # Persistência da URL da API (SharedPreferences)
    storage/secure_token_storage.dart  # Tokens JWT e cache da fazenda (FlutterSecureStorage)
    theme/app_theme.dart               # Tema Material 3 para uso em campo
  models/                              # Farm, AuthTokens, BiometricMeasurement, InferenceRecord
  repositories/                        # AuthRepository, InferenceRepository
  services/media_picker_service.dart   # Câmera, explorador de arquivos e galeria
  state/                               # SettingsProvider, AuthProvider, InferenceProvider
  presentation/
    screens/                           # Login, ServerSettings, HomeShell, NewInference, History, Detail
    widgets/                           # ApiUrlBanner, MeasurementGrid, AnnotatedImageView
  main.dart
```

---

## Como Configurar a Rede Local para Testes em Campo

1. **Descubra o IP da máquina onde o Django está rodando** (PC e celular devem estar no mesmo Wi-Fi):
   * Windows: execute `ipconfig` no PowerShell/CMD e anote o **Endereço IPv4** (ex.: `192.168.0.105`).
   * Linux/macOS: execute `ip addr` ou `ifconfig`.

2. **Suba a API Django em `ovision-ai-api` escutando na rede (`0.0.0.0`):**
   ```powershell
   cd C:\Users\PC-KIRO\Documents\Projetos\ovision-ai-api
   .\.venv\Scripts\python.exe manage.py migrate
   .\.venv\Scripts\python.exe manage.py seed_farm
   .\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
   ```
   *(Não utilize `127.0.0.1` no celular físico: no aparelho, `127.0.0.1` aponta para o próprio telefone. Se usar emulador Android no mesmo PC, o endereço especial é `http://10.0.2.2:8000`.)*

3. **Firewall no Windows:** caso o celular não alcance o servidor, libere a porta TCP `8000` (ou `8009`) para rede privada no Windows Defender Firewall.

4. **No aplicativo Flutter:** toque em **Servidor da API -> Alterar**, informe `http://<IP-DO-PC>:8000`, toque em **Testar conexão** e depois em **Salvar URL da API**.

---

## Permissões Nativas Já Configuradas

* **Android (`android/app/src/main/AndroidManifest.xml` e `res/xml/network_security_config.xml`):**
  * `INTERNET` e `ACCESS_NETWORK_STATE`
  * `CAMERA`
  * `READ_MEDIA_IMAGES` (Android 13+) e `READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`)
  * `android:usesCleartextTraffic="true"` + `network_security_config.xml` liberando HTTP (`http://`) na rede local durante desenvolvimento.
* **iOS (`ios/Runner/Info.plist`):**
  * `NSCameraUsageDescription` e `NSPhotoLibraryUsageDescription`
  * `NSAppTransportSecurity` com `NSAllowsLocalNetworking` e `NSAllowsArbitraryLoads` para testes HTTP na rede local.

---

## Como Inicializar e Rodar o App Flutter

> Caso este diretório contenha apenas os fontes Dart, manifestos e `pubspec.yaml` (sem os arquivos binários gerados de Gradle/Xcode), gere primeiro os runners nativos na raiz de `ovision-app` sem sobrescrever os arquivos já existentes:

```bash
cd ovision-app
flutter create . --project-name ovision_app --org com.ovision --platforms android,ios
flutter pub get
flutter analyze
flutter test
flutter run
```

*(Nota: se o `flutter create` perguntar ou se algum manifesto for recriado, verifique com `git diff` se `pubspec.yaml`, `lib/`, `test/`, `android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist` mantiveram as permissões de câmera, arquivos e HTTP cleartext.)*
