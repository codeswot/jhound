import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:nostr_tools/nostr_tools.dart';

import 'bunker_uri.dart';

const int kNip46Kind = 24133;
const Duration _kRequestTimeout = Duration(seconds: 60);

class Nip46Error implements Exception {
  Nip46Error(this.message);
  final String message;
  @override
  String toString() => 'Nip46Error: $message';
}

class Nip46Client {
  Nip46Client({required this.bunker, required this.onLog});

  final BunkerUri bunker;
  final void Function(String) onLog;

  final _keys = KeyApi();
  final _events = EventApi();
  final _nip04 = Nip04();
  final _pending = <String, Completer<Map<String, dynamic>>>{};

  late final String _clientPrivKey = _keys.generatePrivateKey();
  late final String clientPubkey = _keys.getPublicKey(_clientPrivKey);

  RelayApi? _relay;
  StreamSubscription<Message>? _sub;
  String? _userPubkey;
  String? get userPubkey => _userPubkey;
  bool _connected = false;

  Future<void> open() async {
    final relayUrl = bunker.relays.first;
    onLog('opening relay $relayUrl');
    final relay = RelayApi(relayUrl: relayUrl);
    final stream = await relay.connect();
    _relay = relay;
    _sub = stream.listen(_onMessage, onError: (Object err) => onLog('relay err: $err'));

    relay.sub([
      Filter(
        kinds: [kNip46Kind],
        p: [clientPubkey],
        authors: [bunker.remoteSignerPubkey],
        limit: 0,
      ),
    ]);

    onLog('sending connect');
    final params = <String>[
      bunker.remoteSignerPubkey,
      bunker.secret ?? '',
      'sign_event:22242',
    ];
    final result = await _request('connect', params);
    if (result is String && (result == 'ack' || result.isNotEmpty)) {
      _connected = true;
      onLog('connect ack');
    } else {
      throw Nip46Error('connect refused: $result');
    }
  }

  Future<Event> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    if (!_connected) throw Nip46Error('not connected — call open() first');
    final unsigned = {
      'kind': kind,
      'tags': tags,
      'content': content,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    onLog('requesting sign_event kind=$kind');
    final result = await _request('sign_event', [jsonEncode(unsigned)]);
    if (result is! String) {
      throw Nip46Error('sign_event bad result type: ${result.runtimeType}');
    }
    final Map<String, dynamic> json = jsonDecode(result) as Map<String, dynamic>;
    final event = Event(
      id: json['id'] as String,
      pubkey: json['pubkey'] as String,
      created_at: json['created_at'] as int,
      kind: json['kind'] as int,
      tags: (json['tags'] as List)
          .map((t) => (t as List).map((x) => x as String).toList())
          .toList(),
      content: json['content'] as String,
      sig: json['sig'] as String,
      verify: false,
    );
    if (!_events.verifySignature(event)) {
      throw Nip46Error('signed event failed local verify');
    }
    _userPubkey = event.pubkey;
    return event;
  }

  Future<void> close() async {
    await _sub?.cancel();
    _relay?.close();
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(Nip46Error('client closed'));
    }
    _pending.clear();
  }

  Future<dynamic> _request(String method, List<String> params) async {
    final id = _randomId();
    final body = jsonEncode({'id': id, 'method': method, 'params': params});
    final cipher = _nip04.encrypt(_clientPrivKey, bunker.remoteSignerPubkey, body);

    final req = Event(
      kind: kNip46Kind,
      tags: [
        ['p', bunker.remoteSignerPubkey],
      ],
      content: cipher,
      created_at: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubkey: clientPubkey,
    );
    final signed = _events.finishEvent(req, _clientPrivKey);
    _relay?.publish(signed);

    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      final res = await completer.future.timeout(_kRequestTimeout);
      if (res['error'] != null && (res['error'] as String).isNotEmpty) {
        throw Nip46Error('signer error: ${res['error']}');
      }
      return res['result'];
    } finally {
      _pending.remove(id);
    }
  }

  void _onMessage(Message msg) {
    if (msg.type != 'EVENT') return;
    final event = msg.message as Event;
    if (event.kind != kNip46Kind) return;
    if (event.pubkey != bunker.remoteSignerPubkey) return;
    String plain;
    try {
      plain = _nip04.decrypt(_clientPrivKey, event.pubkey, event.content);
    } catch (err) {
      onLog('decrypt fail: $err');
      return;
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(plain) as Map<String, dynamic>;
    } catch (err) {
      onLog('bad json from signer: $err');
      return;
    }
    final id = body['id'] as String?;
    if (id == null) return;
    final completer = _pending[id];
    if (completer == null || completer.isCompleted) return;
    completer.complete(body);
  }

  String _randomId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(8, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
