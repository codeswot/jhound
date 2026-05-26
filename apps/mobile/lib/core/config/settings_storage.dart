import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsStorage {
  SettingsStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kBaseUrl = 'api_base_url';
  static const _kToken = 'api_token';

  Future<({String? baseUrl, String? token})> read() async {
    final baseUrl = await _storage.read(key: _kBaseUrl);
    final token = await _storage.read(key: _kToken);
    return (baseUrl: baseUrl, token: token);
  }

  Future<void> write({required String baseUrl, required String token}) async {
    await _storage.write(key: _kBaseUrl, value: baseUrl);
    await _storage.write(key: _kToken, value: token);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kBaseUrl);
    await _storage.delete(key: _kToken);
  }
}
