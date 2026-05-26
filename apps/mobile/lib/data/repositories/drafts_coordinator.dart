import 'dart:async';

import 'package:drift/drift.dart';

import '../db/app_db.dart';
import 'drafts_repository.dart';

const _kSyncStateDirty = 'dirty';
const _kSyncStateSynced = 'synced';

String _joinCsv(List<String>? list) => (list ?? const []).join(',');
List<String> _splitCsv(String? csv) =>
    (csv == null || csv.isEmpty) ? const [] : csv.split(',').where((e) => e.isNotEmpty).toList();

class DraftsCoordinator {
  DraftsCoordinator(this._db, this._api);

  final AppDb _db;
  final DraftsRepository _api;

  Stream<List<LocalDraft>> watch() => _db.watchDrafts();

  Future<LocalDraft?> findByLocalId(String localId) async {
    return (_db.select(_db.localDrafts)..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  Future<LocalDraft> create({
    required List<String> toAddresses,
    String? jobId,
    String? replyToResendId,
    List<String>? ccAddresses,
    List<String>? bccAddresses,
    String? replyTo,
    String? subject,
    String? bodyHtml,
    String? bodyText,
  }) async {
    final companion = LocalDraftsCompanion.insert(
      toAddresses: _joinCsv(toAddresses),
      updatedAt: DateTime.now(),
      jobId: Value(jobId),
      replyToResendId: Value(replyToResendId),
      ccAddresses: Value(ccAddresses == null ? null : _joinCsv(ccAddresses)),
      bccAddresses: Value(bccAddresses == null ? null : _joinCsv(bccAddresses)),
      replyTo: Value(replyTo),
      subject: Value(subject),
      bodyHtml: Value(bodyHtml),
      bodyText: Value(bodyText),
      syncState: const Value(_kSyncStateDirty),
    );
    final inserted = await _db.into(_db.localDrafts).insertReturning(companion);
    unawaited(_push(inserted));
    return inserted;
  }

  Future<LocalDraft> update(String localId, {
    List<String>? toAddresses,
    List<String>? ccAddresses,
    List<String>? bccAddresses,
    String? subject,
    String? bodyHtml,
    String? bodyText,
  }) async {
    final existing = await findByLocalId(localId);
    if (existing == null) throw StateError('draft $localId not found');

    await (_db.update(_db.localDrafts)..where((t) => t.localId.equals(localId))).write(
      LocalDraftsCompanion(
        toAddresses: toAddresses != null ? Value(_joinCsv(toAddresses)) : const Value.absent(),
        ccAddresses: ccAddresses != null ? Value(_joinCsv(ccAddresses)) : const Value.absent(),
        bccAddresses: bccAddresses != null ? Value(_joinCsv(bccAddresses)) : const Value.absent(),
        subject: subject != null ? Value(subject) : const Value.absent(),
        bodyHtml: bodyHtml != null ? Value(bodyHtml) : const Value.absent(),
        bodyText: bodyText != null ? Value(bodyText) : const Value.absent(),
        syncState: const Value(_kSyncStateDirty),
        updatedAt: Value(DateTime.now()),
      ),
    );

    final updated = (await findByLocalId(localId))!;
    unawaited(_push(updated));
    return updated;
  }

  Future<void> remove(String localId) async {
    final existing = await findByLocalId(localId);
    if (existing == null) return;
    if (existing.remoteId != null) {
      try {
        await _api.remove(existing.remoteId!);
      } catch (_) {/* tolerate offline */}
    }
    await _db.deleteDraft(localId);
  }

  Future<({String resendId, DateTime sentAt})> send(String localId) async {
    var draft = (await findByLocalId(localId)) ?? (throw StateError('not found'));

    if (draft.syncState != _kSyncStateSynced || draft.remoteId == null) {
      draft = await _push(draft) ?? draft;
      if (draft.remoteId == null) {
        throw StateError('cannot send: draft not pushed to server');
      }
    }

    final result = await _api.send(draft.remoteId!);

    await (_db.update(_db.localDrafts)..where((t) => t.localId.equals(localId))).write(
      LocalDraftsCompanion(
        sentResendId: Value(result.resendId),
        sentAt: Value(result.sentAt),
        syncState: const Value('sent'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return result;
  }

  Future<LocalDraft?> _push(LocalDraft local) async {
    try {
      if (local.remoteId == null) {
        final remote = await _api.create(
          toAddresses: _splitCsv(local.toAddresses),
          jobId: local.jobId,
          replyToResendId: local.replyToResendId,
          ccAddresses: local.ccAddresses == null ? null : _splitCsv(local.ccAddresses),
          bccAddresses: local.bccAddresses == null ? null : _splitCsv(local.bccAddresses),
          replyTo: local.replyTo,
          subject: local.subject,
          bodyHtml: local.bodyHtml,
          bodyText: local.bodyText,
        );
        await (_db.update(_db.localDrafts)..where((t) => t.localId.equals(local.localId))).write(
          LocalDraftsCompanion(
            remoteId: Value(remote.id),
            syncState: const Value(_kSyncStateSynced),
          ),
        );
        return findByLocalId(local.localId);
      }

      await _api.patch(local.remoteId!, {
        'to_addresses': _splitCsv(local.toAddresses),
        'cc_addresses': local.ccAddresses == null ? null : _splitCsv(local.ccAddresses),
        'bcc_addresses': local.bccAddresses == null ? null : _splitCsv(local.bccAddresses),
        if (local.subject != null) 'subject': local.subject,
        if (local.bodyText != null) 'body_text': local.bodyText,
        if (local.bodyHtml != null) 'body_html': local.bodyHtml,
      });
      await (_db.update(_db.localDrafts)..where((t) => t.localId.equals(local.localId))).write(
        const LocalDraftsCompanion(syncState: Value(_kSyncStateSynced)),
      );
      return findByLocalId(local.localId);
    } catch (_) {
      return local;
    }
  }

  Future<void> refresh() async {
    try {
      final remotes = await _api.list(limit: 100);
      for (final r in remotes) {
        final existing = await (_db.select(_db.localDrafts)
              ..where((t) => t.remoteId.equals(r.id)))
            .getSingleOrNull();
        if (existing != null) continue;
        await _db.into(_db.localDrafts).insert(
              LocalDraftsCompanion.insert(
                toAddresses: _joinCsv(r.toAddresses),
                updatedAt: r.updatedAt,
                remoteId: Value(r.id),
                jobId: Value(r.jobId),
                replyToResendId: Value(r.replyToResendId),
                ccAddresses: Value(r.ccAddresses == null ? null : _joinCsv(r.ccAddresses!)),
                bccAddresses: Value(r.bccAddresses == null ? null : _joinCsv(r.bccAddresses!)),
                replyTo: Value(r.replyTo),
                subject: Value(r.subject),
                bodyHtml: Value(r.bodyHtml),
                bodyText: Value(r.bodyText),
                syncState: const Value(_kSyncStateSynced),
                sentResendId: Value(r.sentResendId),
                sentAt: Value(r.sentAt),
              ),
            );
      }
    } catch (_) {/* tolerate offline */}
  }
}
