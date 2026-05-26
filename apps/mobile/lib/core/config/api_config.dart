class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.token});

  final String baseUrl;
  final String token;

  Uri restUri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+\$'), '')}/v1$path',
      queryParameters: query?.map((k, v) => MapEntry(k, v?.toString())),
    );
  }

  String get wsUrl {
    final u = Uri.parse(baseUrl);
    final scheme = u.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${u.authority}';
  }
}
