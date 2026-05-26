import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService(this._storage);

  final FlutterSecureStorage _storage;

  static const _kPinHash = 'pin_hash';
  static const _kPinSalt = 'pin_salt';
  static const _kAttempts = 'pin_attempts';
  static const _kBioEnabled = 'pin_bio_enabled';

  static const int maxAttempts = 5;

  Future<bool> hasPin() async => (await _storage.read(key: _kPinHash)) != null;

  Future<void> setPin(String pin) async {
    if (pin.length < 4 || pin.length > 12 || !RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw ArgumentError('PIN must be 4-12 digits');
    }
    final salt = _randomSalt();
    final hash = _hash(pin, salt);
    await _storage.write(key: _kPinSalt, value: base64Encode(salt));
    await _storage.write(key: _kPinHash, value: hash);
    await _storage.write(key: _kAttempts, value: '0');
  }

  Future<bool> verify(String pin) async {
    final salt = await _storage.read(key: _kPinSalt);
    final stored = await _storage.read(key: _kPinHash);
    if (salt == null || stored == null) return false;
    final candidate = _hash(pin, base64Decode(salt));
    final ok = _constTimeEqual(candidate, stored);
    if (ok) {
      await _storage.write(key: _kAttempts, value: '0');
    } else {
      final n = int.tryParse(await _storage.read(key: _kAttempts) ?? '0') ?? 0;
      await _storage.write(key: _kAttempts, value: '${n + 1}');
    }
    return ok;
  }

  Future<int> attempts() async =>
      int.tryParse(await _storage.read(key: _kAttempts) ?? '0') ?? 0;

  Future<bool> biometricEnabled() async =>
      (await _storage.read(key: _kBioEnabled)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) async =>
      _storage.write(key: _kBioEnabled, value: enabled ? 'true' : 'false');

  Future<void> reset() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kAttempts);
    await _storage.delete(key: _kBioEnabled);
  }

  String _hash(String pin, List<int> salt) {
    final mac = Hmac(sha256, salt);
    final digest = mac.convert(utf8.encode(pin));
    return digest.toString();
  }

  Uint8List _randomSalt() {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  bool _constTimeEqual(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
