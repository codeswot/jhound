import 'dart:async';

import 'package:dio/dio.dart';

import 'bunker_uri.dart';
import 'nip46_client.dart';

class AuthResult {
  const AuthResult({required this.token, required this.pubkey, required this.expiresIn});
  final String token;
  final String pubkey;
  final int expiresIn;
}

class NostrAuthFlow {
  NostrAuthFlow({required this.apiBaseUrl, this.onLog});

  final String apiBaseUrl;
  final void Function(String)? onLog;

  Future<AuthResult> pair(String bunkerUri) async {
    final bunker = BunkerUri.parse(bunkerUri);
    onLog?.call('bunker parsed, pubkey=${bunker.remoteSignerPubkey.substring(0, 12)}…');

    final client = Nip46Client(bunker: bunker, onLog: (m) => onLog?.call('nip46: $m'));
    try {
      await client.open();

      final dio = Dio(BaseOptions(
        baseUrl: '${_strip(apiBaseUrl)}/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));

      onLog?.call('GET /v1/auth/challenge');
      final challenge = await dio.get<Map<String, dynamic>>('/auth/challenge');
      final nonce = challenge.data!['nonce'] as String;

      onLog?.call('signing auth event');
      final signed = await client.signEvent(
        kind: 22242,
        content: '',
        tags: [
          ['challenge', nonce],
          ['relay', apiBaseUrl],
        ],
      );

      onLog?.call('POST /v1/auth/verify');
      final verify = await dio.post<Map<String, dynamic>>(
        '/auth/verify',
        data: {'event': signed.toJson()},
      );

      return AuthResult(
        token: verify.data!['token'] as String,
        pubkey: verify.data!['pubkey'] as String,
        expiresIn: (verify.data!['expires_in'] as num).toInt(),
      );
    } finally {
      await client.close();
    }
  }

  static String _strip(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
