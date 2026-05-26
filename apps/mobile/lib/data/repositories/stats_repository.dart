import '../../core/network/api_client.dart';
import '../models/stats.dart';

class StatsRepository {
  StatsRepository(this._api);

  final ApiClient _api;

  Future<StatsOverview> overview() async {
    final json = await _api.getJson('/stats/overview');
    return StatsOverview.fromJson(json);
  }

  Future<List<Map<String, dynamic>>> weekly() async {
    final list = await _api.getList('/stats/weekly');
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> sources() async {
    final list = await _api.getList('/stats/sources');
    return list.cast<Map<String, dynamic>>();
  }
}
