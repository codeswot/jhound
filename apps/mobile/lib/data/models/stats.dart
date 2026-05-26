class StatsOverview {
  const StatsOverview({
    required this.total,
    required this.today,
    required this.week,
    required this.responses,
    required this.tier1,
    required this.tier2,
    required this.needsReview,
  });

  final int total;
  final int today;
  final int week;
  final int responses;
  final int tier1;
  final int tier2;
  final int needsReview;

  double get responseRate => total == 0 ? 0 : responses / total;

  factory StatsOverview.fromJson(Map<String, dynamic> json) => StatsOverview(
        total: (json['total'] as num?)?.toInt() ?? 0,
        today: (json['today'] as num?)?.toInt() ?? 0,
        week: (json['week'] as num?)?.toInt() ?? 0,
        responses: (json['responses'] as num?)?.toInt() ?? 0,
        tier1: (json['tier1'] as num?)?.toInt() ?? 0,
        tier2: (json['tier2'] as num?)?.toInt() ?? 0,
        needsReview: (json['needs_review'] as num?)?.toInt() ?? 0,
      );
}
