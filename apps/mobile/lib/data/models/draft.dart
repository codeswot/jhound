class Draft {
  const Draft({
    required this.id,
    required this.toAddresses,
    required this.createdAt,
    required this.updatedAt,
    this.jobId,
    this.replyToResendId,
    this.ccAddresses,
    this.bccAddresses,
    this.replyTo,
    this.subject,
    this.bodyHtml,
    this.bodyText,
    this.sentResendId,
    this.sentAt,
  });

  final String id;
  final String? jobId;
  final String? replyToResendId;
  final List<String> toAddresses;
  final List<String>? ccAddresses;
  final List<String>? bccAddresses;
  final String? replyTo;
  final String? subject;
  final String? bodyHtml;
  final String? bodyText;
  final String? sentResendId;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSent => sentAt != null;

  factory Draft.fromJson(Map<String, dynamic> json) => Draft(
        id: json['id'] as String,
        jobId: json['jobId'] as String? ?? json['job_id'] as String?,
        replyToResendId: json['replyToResendId'] as String? ?? json['reply_to_resend_id'] as String?,
        toAddresses: _toList(json['toAddresses'] ?? json['to_addresses']),
        ccAddresses: _toListOrNull(json['ccAddresses'] ?? json['cc_addresses']),
        bccAddresses: _toListOrNull(json['bccAddresses'] ?? json['bcc_addresses']),
        replyTo: json['replyTo'] as String? ?? json['reply_to'] as String?,
        subject: json['subject'] as String?,
        bodyHtml: json['bodyHtml'] as String? ?? json['body_html'] as String?,
        bodyText: json['bodyText'] as String? ?? json['body_text'] as String?,
        sentResendId: json['sentResendId'] as String? ?? json['sent_resend_id'] as String?,
        sentAt: _parseDt(json['sentAt'] ?? json['sent_at']),
        createdAt: _parseDt(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
        updatedAt: _parseDt(json['updatedAt'] ?? json['updated_at']) ?? DateTime.now(),
      );

  static List<String> _toList(dynamic v) =>
      v is List ? v.cast<String>() : const [];

  static List<String>? _toListOrNull(dynamic v) =>
      v is List ? v.cast<String>() : null;

  static DateTime? _parseDt(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
