import '../../core/network/api_client.dart';
import '../models/draft.dart';

class DraftsRepository {
  DraftsRepository(this._api);

  final ApiClient _api;

  Future<List<Draft>> list({int limit = 50, int offset = 0, bool unsentOnly = false}) async {
    final json = await _api.getJson('/drafts', query: {
      'limit': limit,
      'offset': offset,
      if (unsentOnly) 'unsent_only': true,
    });
    final items = json['items'] as List? ?? const [];
    return items.map((d) => Draft.fromJson(d as Map<String, dynamic>)).toList();
  }

  Future<Draft> findOne(String id) async {
    final json = await _api.getJson('/drafts/$id');
    return Draft.fromJson(json);
  }

  Future<Draft> create({
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
    final json = await _api.postJson('/drafts', body: {
      'to_addresses': toAddresses,
      if (jobId != null) 'job_id': jobId,
      if (replyToResendId != null) 'reply_to_resend_id': replyToResendId,
      if (ccAddresses != null) 'cc_addresses': ccAddresses,
      if (bccAddresses != null) 'bcc_addresses': bccAddresses,
      if (replyTo != null) 'reply_to': replyTo,
      if (subject != null) 'subject': subject,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (bodyText != null) 'body_text': bodyText,
    });
    return Draft.fromJson(json);
  }

  Future<Draft> patch(String id, Map<String, dynamic> changes) async {
    final json = await _api.patchJson('/drafts/$id', body: changes);
    return Draft.fromJson(json);
  }

  Future<void> remove(String id) => _api.delete('/drafts/$id');

  Future<({String resendId, DateTime sentAt})> send(String id, {String? idempotencyKey}) async {
    final json = await _api.postJson(
      '/drafts/$id/send',
      headers: idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
    );
    return (
      resendId: json['resend_id'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }
}
