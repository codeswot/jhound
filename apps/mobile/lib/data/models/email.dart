class EmailSummary {
  const EmailSummary({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.createdAt,
    required this.direction,
    this.lastEvent,
    this.hasAttachments = false,
  });

  final String id;
  final String from;
  final List<String> to;
  final String? subject;
  final DateTime createdAt;
  final EmailDirection direction;
  final String? lastEvent;
  final bool hasAttachments;

  factory EmailSummary.received(Map<String, dynamic> json) => EmailSummary(
        id: json['id'] as String,
        from: json['from'] as String? ?? '',
        to: _toList(json['to']),
        subject: json['subject'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        direction: EmailDirection.inbound,
        hasAttachments: (json['attachments'] as List?)?.isNotEmpty ?? false,
      );

  factory EmailSummary.sent(Map<String, dynamic> json) => EmailSummary(
        id: json['id'] as String,
        from: json['from'] as String? ?? '',
        to: _toList(json['to']),
        subject: json['subject'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        direction: EmailDirection.outbound,
        lastEvent: json['last_event'] as String?,
      );

  static List<String> _toList(dynamic v) {
    if (v is List) return v.cast<String>();
    if (v is String) return [v];
    return const [];
  }
}

enum EmailDirection { inbound, outbound }

class AttachmentInfo {
  const AttachmentInfo({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.size,
  });

  final String id;
  final String filename;
  final String contentType;
  final int size;

  factory AttachmentInfo.fromJson(Map<String, dynamic> json) => AttachmentInfo(
        id: json['id'] as String,
        filename: json['filename'] as String? ?? 'attachment',
        contentType: json['content_type'] as String? ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class EmailPage {
  const EmailPage({required this.items, required this.hasMore});

  final List<EmailSummary> items;
  final bool hasMore;
}

class EmailBody {
  const EmailBody({
    required this.id,
    required this.from,
    required this.to,
    required this.createdAt,
    this.subject,
    this.html,
    this.text,
    this.lastEvent,
    this.attachments = const [],
  });

  final String id;
  final String from;
  final List<String> to;
  final String? subject;
  final DateTime createdAt;
  final String? html;
  final String? text;
  final String? lastEvent;
  final List<AttachmentInfo> attachments;

  factory EmailBody.fromJson(Map<String, dynamic> json) => EmailBody(
        id: json['id'] as String,
        from: json['from'] as String? ?? '',
        to: EmailSummary._toList(json['to']),
        subject: json['subject'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        html: json['html'] as String?,
        text: json['text'] as String?,
        lastEvent: json['last_event'] as String?,
        attachments:
            json['attachments'] is List
                ? (json['attachments'] as List)
                    .map((a) => AttachmentInfo.fromJson(a as Map<String, dynamic>))
                    .toList()
                : const [],
      );
}
