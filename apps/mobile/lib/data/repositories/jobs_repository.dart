import '../../core/network/api_client.dart';
import '../models/job.dart';

class JobsRepository {
  JobsRepository(this._api);

  final ApiClient _api;

  Future<JobList> list({
    int limit = 50,
    int offset = 0,
    String? status,
    String? source,
    int? tier,
    String? q,
    String sort = 'applied_at',
  }) async {
    final json = await _api.getJson('/jobs', query: {
      'limit': limit,
      'offset': offset,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (tier != null) 'tier': tier,
      if (q != null && q.isNotEmpty) 'q': q,
      'sort': sort,
    });
    return JobList.fromJson(json);
  }

  Future<Job> findOne(String id) async {
    final json = await _api.getJson('/jobs/$id');
    return Job.fromJson(json);
  }
}
