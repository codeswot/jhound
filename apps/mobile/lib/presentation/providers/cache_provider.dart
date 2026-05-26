import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/email_cache.dart';
import 'api_provider.dart';
import 'db_provider.dart';

final emailCacheProvider = Provider<EmailCacheService>((ref) {
  return EmailCacheService(ref.watch(appDbProvider), ref.watch(emailsRepoProvider));
});
