import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/api_config.dart';
import '../../core/config/env.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final apiConfigProvider = Provider<ApiConfig>((ref) {
  if (jhoundBaseUrl.isEmpty || jhoundApiToken.isEmpty) {
    throw StateError(
      'JHOUND_API_BASE_URL and JHOUND_API_TOKEN must be set via --dart-define.\n'
      'Add to .vscode/launch.json:\n'
      '  "args": ["--dart-define=JHOUND_API_BASE_URL=https://api.example.com",\n'
      '           "--dart-define=JHOUND_API_TOKEN=your-token"]',
    );
  }
  return const ApiConfig(baseUrl: jhoundBaseUrl, token: jhoundApiToken);
});
