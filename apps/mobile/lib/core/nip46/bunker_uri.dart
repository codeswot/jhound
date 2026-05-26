class BunkerUri {
  const BunkerUri({
    required this.remoteSignerPubkey,
    required this.relays,
    this.secret,
  });

  final String remoteSignerPubkey;
  final List<String> relays;
  final String? secret;

  static BunkerUri parse(String input) {
    final trimmed = input.trim();
    if (!trimmed.startsWith('bunker://')) {
      throw const FormatException('not a bunker:// URI');
    }
    final raw = trimmed.substring('bunker://'.length);
    final qIdx = raw.indexOf('?');
    final host = (qIdx == -1 ? raw : raw.substring(0, qIdx)).toLowerCase();
    if (!_isHex32(host)) {
      throw const FormatException('bunker host must be 32-byte hex pubkey');
    }

    final relays = <String>[];
    String? secret;
    if (qIdx != -1) {
      final query = raw.substring(qIdx + 1);
      for (final part in query.split('&')) {
        if (part.isEmpty) continue;
        final eq = part.indexOf('=');
        if (eq < 0) continue;
        final key = part.substring(0, eq);
        final value = Uri.decodeQueryComponent(part.substring(eq + 1));
        switch (key) {
          case 'relay':
            relays.add(value);
            break;
          case 'secret':
            secret = value;
            break;
        }
      }
    }
    if (relays.isEmpty) {
      throw const FormatException('bunker URI must include at least one ?relay=');
    }
    return BunkerUri(remoteSignerPubkey: host, relays: relays, secret: secret);
  }

  static bool _isHex32(String s) =>
      s.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(s);
}
