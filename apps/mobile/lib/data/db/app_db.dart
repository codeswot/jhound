import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_db.g.dart';

class CachedJobs extends Table {
  TextColumn get id => text()();
  TextColumn get jobTitle => text()();
  TextColumn get company => text()();
  TextColumn get sourceBoard => text()();
  TextColumn get jobUrl => text()();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  IntColumn get tier => integer().nullable()();
  RealColumn get matchScore => real().nullable()();
  DateTimeColumn get appliedAt => dateTime()();
  DateTimeColumn get responseReceivedAt => dateTime().nullable()();
  TextColumn get rawJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedEmailBodies extends Table {
  TextColumn get resendId => text()();
  TextColumn get direction => text()();
  TextColumn get bodyHtml => text().nullable()();
  TextColumn get bodyText => text().nullable()();
  TextColumn get rawJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {resendId};
}

class LocalDrafts extends Table {
  TextColumn get localId => text().clientDefault(_uuid)();
  TextColumn get remoteId => text().nullable()();
  TextColumn get jobId => text().nullable()();
  TextColumn get replyToResendId => text().nullable()();
  TextColumn get toAddresses => text()();
  TextColumn get ccAddresses => text().nullable()();
  TextColumn get bccAddresses => text().nullable()();
  TextColumn get replyTo => text().nullable()();
  TextColumn get subject => text().nullable()();
  TextColumn get bodyHtml => text().nullable()();
  TextColumn get bodyText => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('dirty'))();
  TextColumn get sentResendId => text().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

String _uuid() {
  final r = DateTime.now().microsecondsSinceEpoch;
  return 'd_${r.toRadixString(16)}_${(r ^ (r >> 5)).toRadixString(16)}';
}

@DriftDatabase(tables: [CachedJobs, CachedEmailBodies, LocalDrafts])
class AppDb extends _$AppDb {
  AppDb() : super(_open());
  AppDb.connect(super.connection);

  @override
  int get schemaVersion => 2;

  Future<void> upsertJob(CachedJobsCompanion entry) async {
    await into(cachedJobs).insertOnConflictUpdate(entry);
  }

  Future<void> replaceCachedJobs(List<CachedJobsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(cachedJobs, entries);
    });
  }

  Stream<List<CachedJob>> watchJobs() => select(cachedJobs).watch();

  Stream<List<LocalDraft>> watchDrafts() =>
      (select(localDrafts)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  Future<int> deleteDraft(String localId) =>
      (delete(localDrafts)..where((t) => t.localId.equals(localId))).go();

  Future<CachedEmailBody?> getCachedEmailBody(String resendId) =>
      (select(cachedEmailBodies)..where((t) => t.resendId.equals(resendId))).getSingleOrNull();

  Future<void> upsertEmailBody(CachedEmailBodiesCompanion entry) async {
    await into(cachedEmailBodies).insertOnConflictUpdate(entry);
  }
}

QueryExecutor _open() => driftDatabase(name: 'jhound');
