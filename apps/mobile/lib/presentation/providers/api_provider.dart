import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../data/repositories/drafts_repository.dart';
import '../../data/repositories/emails_repository.dart';
import '../../data/repositories/jobs_repository.dart';
import '../../data/repositories/oss_repository.dart';
import '../../data/repositories/stats_repository.dart';
import 'settings_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(apiConfigProvider));
});

final jobsRepoProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(apiClientProvider));
});

final emailsRepoProvider = Provider<EmailsRepository>((ref) {
  return EmailsRepository(ref.watch(apiClientProvider));
});

final draftsRepoProvider = Provider<DraftsRepository>((ref) {
  return DraftsRepository(ref.watch(apiClientProvider));
});

final statsRepoProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiClientProvider));
});

final ossRepoProvider = Provider<OssRepository>((ref) {
  return OssRepository(ref.watch(apiClientProvider));
});
