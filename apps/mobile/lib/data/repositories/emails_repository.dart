import '../../core/network/api_client.dart';
import '../models/email.dart';

class EmailsRepository {
  EmailsRepository(this._api);

  final ApiClient _api;

  Future<EmailPage> listInbox({int limit = 50, String? after, String? before}) async {
    final json = await _api.getJson('/emails/inbox', query: {
      'limit': limit,
      if (after != null) 'after': after,
      if (before != null) 'before': before,
    });
    return _parsePage(json, (m) => EmailSummary.received(m));
  }

  Future<EmailPage> listSent({int limit = 50, String? after, String? before}) async {
    final json = await _api.getJson('/emails/sent', query: {
      'limit': limit,
      if (after != null) 'after': after,
      if (before != null) 'before': before,
    });
    return _parsePage(json, (m) => EmailSummary.sent(m));
  }

  Future<EmailBody> getInbox(String id) async {
    final json = await _api.getJson('/emails/inbox/$id');
    return EmailBody.fromJson(json);
  }

  Future<EmailBody> getSent(String id) async {
    final json = await _api.getJson('/emails/sent/$id');
    return EmailBody.fromJson(json);
  }

  Future<List<AttachmentInfo>> listAttachments(
    String emailId,
    EmailDirection direction,
  ) async {
    final prefix = direction == EmailDirection.inbound ? 'inbox' : 'sent';
    final json = await _api.getJson('/emails/$prefix/$emailId/attachments');
    final data = json['data'] as List? ?? [];
    return data
        .map((a) => AttachmentInfo.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> downloadAttachment(
    String emailId,
    String attachmentId,
    EmailDirection direction,
  ) async {
    final prefix = direction == EmailDirection.inbound ? 'inbox' : 'sent';
    return _api.downloadBytes('/emails/$prefix/$emailId/attachments/$attachmentId');
  }

  Future<String> send({
    required List<String> to,
    required String subject,
    String? html,
    String? text,
    List<String>? cc,
    List<String>? bcc,
    String? jobId,
    String kind = 'manual',
  }) async {
    return sendRaw(
      to: to,
      subject: subject,
      html: html,
      text: text,
      cc: cc,
      bcc: bcc,
      jobId: jobId,
      kind: kind,
    );
  }

  Future<String> sendRaw({
    required List<String> to,
    required String subject,
    String? html,
    String? text,
    List<String>? cc,
    List<String>? bcc,
    String? jobId,
    String kind = 'manual',
    List<Map<String, String>>? attachments,
  }) async {
    final res = await _api.postJson('/emails/send', body: {
      'to': to,
      'subject': subject,
      if (html != null) 'html': html,
      if (text != null) 'text': text,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
      if (jobId != null) 'job_id': jobId,
      'kind': kind,
      if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
    });
    return res['id'] as String;
  }

  Future<String> reply(
    String inboundId, {
    String? html,
    String? text,
    String? subject,
    String? jobId,
  }) async {
    final res = await _api.postJson('/emails/inbox/$inboundId/reply', body: {
      if (html != null) 'html': html,
      if (text != null) 'text': text,
      if (subject != null) 'subject': subject,
      if (jobId != null) 'job_id': jobId,
    });
    return res['id'] as String;
  }

  EmailPage _parsePage(
    Map<String, dynamic> json,
    EmailSummary Function(Map<String, dynamic>) factory,
  ) {
    final data = json['data'] as List? ?? [];
    return EmailPage(
      items: data.map((e) => factory(e as Map<String, dynamic>)).toList(),
      hasMore: json['has_more'] == true,
    );
  }
}
