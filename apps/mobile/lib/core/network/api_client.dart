import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiClient {
  ApiClient(ApiConfig config)
      : _dio = Dio(
          BaseOptions(
            baseUrl: '${_stripTrailingSlash(config.baseUrl)}/v1',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Authorization': 'Bearer ${config.token}',
              'Accept': 'application/json',
            },
            responseType: ResponseType.json,
          ),
        );

  final Dio _dio;

  Dio get raw => _dio;

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<dynamic>(path, queryParameters: query);
    return _asMap(res.data);
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<dynamic>(path, queryParameters: query);
    if (res.data is List) return res.data as List<dynamic>;
    final map = _asMap(res.data);
    if (map['data'] is List) return map['data'] as List<dynamic>;
    if (map['items'] is List) return map['items'] as List<dynamic>;
    throw StateError('expected list at $path, got ${res.data.runtimeType}');
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body, Map<String, String>? headers}) async {
    final res = await _dio.post<dynamic>(
      path,
      data: body,
      options: Options(headers: headers),
    );
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> patchJson(String path, {Object? body}) async {
    final res = await _dio.patch<dynamic>(path, data: body);
    return _asMap(res.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete<dynamic>(path);
  }

  Future<List<int>> downloadBytes(String path) async {
    final res = await _dio.get<List<int>>(
      path,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data!;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('expected JSON object, got ${data.runtimeType}');
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
