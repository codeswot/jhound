import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_db.dart';

final appDbProvider = Provider<AppDb>((ref) {
  final db = AppDb();
  ref.onDispose(db.close);
  return db;
});
