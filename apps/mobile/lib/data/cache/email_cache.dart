import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_db.dart';
import '../models/email.dart';
import '../repositories/emails_repository.dart';

class EmailCacheService {
  EmailCacheService(this._db, this._api);

  final AppDb _db;
  final EmailsRepository _api;

  Future<EmailBody> getBody(String id, EmailDirection direction) async {
    final cached = await _db.getCachedEmailBody(id);
    if (cached != null) {
      return EmailBody.fromJson(jsonDecode(cached.rawJson) as Map<String, dynamic>);
    }
    final body = direction == EmailDirection.inbound
        ? await _api.getInbox(id)
        : await _api.getSent(id);
    await _db.upsertEmailBody(CachedEmailBodiesCompanion.insert(
      resendId: id,
      direction: direction == EmailDirection.inbound ? 'inbound' : 'outbound',
      bodyHtml: Value(body.html),
      bodyText: Value(body.text),
      rawJson: jsonEncode(_bodyToJson(body)),
      fetchedAt: DateTime.now(),
    ));
    return body;
  }

  Map<String, dynamic> _bodyToJson(EmailBody body) => {
        'id': body.id,
        'from': body.from,
        'to': body.to,
        'subject': body.subject,
        'html': body.html,
        'text': body.text,
        'last_event': body.lastEvent,
        'created_at': body.createdAt.toIso8601String(),
        'attachments': body.attachments
            .map((a) => {
                  'id': a.id,
                  'filename': a.filename,
                  'content_type': a.contentType,
                  'size': a.size,
                })
            .toList(),
      };
}
