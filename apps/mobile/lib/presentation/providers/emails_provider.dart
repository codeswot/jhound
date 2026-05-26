import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/email.dart';
import 'api_provider.dart';
import 'cache_provider.dart';

final inboxProvider = FutureProvider.autoDispose<EmailPage>((ref) async {
  final repo = ref.watch(emailsRepoProvider);
  return repo.listInbox(limit: 50);
});

final sentProvider = FutureProvider.autoDispose<EmailPage>((ref) async {
  final repo = ref.watch(emailsRepoProvider);
  return repo.listSent(limit: 50);
});

final emailBodyProvider =
    FutureProvider.autoDispose.family<EmailBody, ({String id, EmailDirection direction})>(
  (ref, key) async {
    final cache = ref.watch(emailCacheProvider);
    return cache.getBody(key.id, key.direction);
  },
);

final emailAttachmentsProvider = FutureProvider.autoDispose
    .family<List<AttachmentInfo>, ({String id, EmailDirection direction})>(
  (ref, key) async {
    final repo = ref.watch(emailsRepoProvider);
    return repo.listAttachments(key.id, key.direction);
  },
);
