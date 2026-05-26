import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_db.dart';
import '../../data/repositories/drafts_coordinator.dart';
import 'api_provider.dart';
import 'db_provider.dart';

final draftsCoordinatorProvider = Provider<DraftsCoordinator>((ref) {
  return DraftsCoordinator(ref.watch(appDbProvider), ref.watch(draftsRepoProvider));
});

final draftsStreamProvider = StreamProvider.autoDispose<List<LocalDraft>>((ref) {
  return ref.watch(draftsCoordinatorProvider).watch();
});

final draftByIdProvider =
    FutureProvider.autoDispose.family<LocalDraft?, String>((ref, localId) async {
  return ref.watch(draftsCoordinatorProvider).findByLocalId(localId);
});
