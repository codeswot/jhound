class Job {
  const Job({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.jobUrl,
    required this.sourceBoard,
    required this.applicationMethod,
    required this.status,
    required this.appliedAt,
    this.tier,
    this.matchScore,
    this.companyDomain,
    this.location,
    this.hiringManagerEmail,
    this.hiringManagerName,
    this.responseReceivedAt,
    this.responseType,
    this.aiTags,
  });

  final String id;
  final String jobTitle;
  final String company;
  final String? companyDomain;
  final String jobUrl;
  final String sourceBoard;
  final String? location;
  final String applicationMethod;
  final String status;
  final DateTime appliedAt;
  final int? tier;
  final double? matchScore;
  final String? hiringManagerEmail;
  final String? hiringManagerName;
  final DateTime? responseReceivedAt;
  final String? responseType;
  final List<String>? aiTags;

  bool get hasResponse => responseReceivedAt != null;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String? ?? json['job_title'] as String,
      company: json['company'] as String,
      companyDomain: json['companyDomain'] as String? ?? json['company_domain'] as String?,
      jobUrl: json['jobUrl'] as String? ?? json['job_url'] as String,
      sourceBoard: json['sourceBoard'] as String? ?? json['source_board'] as String,
      location: json['location'] as String?,
      applicationMethod: json['applicationMethod'] as String? ??
          json['application_method'] as String,
      status: json['status'] as String? ?? 'applied',
      appliedAt: DateTime.parse(json['appliedAt'] as String? ?? json['applied_at'] as String),
      tier: (json['aiPriorityTier'] ?? json['ai_priority_tier']) as int?,
      matchScore: (json['aiJobMatchScore'] ?? json['ai_job_match_score'] as num?)?.toDouble(),
      hiringManagerEmail:
          json['hiringManagerEmail'] as String? ?? json['hiring_manager_email'] as String?,
      hiringManagerName:
          json['hiringManagerName'] as String? ?? json['hiring_manager_name'] as String?,
      responseReceivedAt: _parseDt(json['responseReceivedAt'] ?? json['response_received_at']),
      responseType: json['responseType'] as String? ?? json['response_type'] as String?,
      aiTags: (json['aiTags'] ?? json['ai_tags']) is List
          ? List<String>.from((json['aiTags'] ?? json['ai_tags']) as List)
          : null,
    );
  }

  static DateTime? _parseDt(dynamic v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

class JobList {
  const JobList({required this.items, required this.total, required this.limit, required this.offset});

  final List<Job> items;
  final int total;
  final int limit;
  final int offset;

  factory JobList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List? ?? const [];
    return JobList(
      items: raw.map((j) => Job.fromJson(j as Map<String, dynamic>)).toList(),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      limit: (json['limit'] as num?)?.toInt() ?? 50,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }
}
