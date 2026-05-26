import '../../core/network/api_client.dart';

class OssRepository {
  OssRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> list({int limit = 50, int offset = 0, String sort = 'discovered_at'}) async {
    return _api.getJson('/oss', query: {'limit': limit, 'offset': offset, 'sort': sort});
  }

  Future<Map<String, dynamic>> findOne(String id) async {
    return _api.getJson('/oss/$id');
  }
}
