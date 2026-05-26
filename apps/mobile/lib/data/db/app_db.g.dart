// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $CachedJobsTable extends CachedJobs
    with TableInfo<$CachedJobsTable, CachedJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobTitleMeta =
      const VerificationMeta('jobTitle');
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
      'job_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _companyMeta =
      const VerificationMeta('company');
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
      'company', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceBoardMeta =
      const VerificationMeta('sourceBoard');
  @override
  late final GeneratedColumn<String> sourceBoard = GeneratedColumn<String>(
      'source_board', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobUrlMeta = const VerificationMeta('jobUrl');
  @override
  late final GeneratedColumn<String> jobUrl = GeneratedColumn<String>(
      'job_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('applied'));
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<int> tier = GeneratedColumn<int>(
      'tier', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _matchScoreMeta =
      const VerificationMeta('matchScore');
  @override
  late final GeneratedColumn<double> matchScore = GeneratedColumn<double>(
      'match_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _appliedAtMeta =
      const VerificationMeta('appliedAt');
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
      'applied_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _responseReceivedAtMeta =
      const VerificationMeta('responseReceivedAt');
  @override
  late final GeneratedColumn<DateTime> responseReceivedAt =
      GeneratedColumn<DateTime>('response_received_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _rawJsonMeta =
      const VerificationMeta('rawJson');
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
      'raw_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        jobTitle,
        company,
        sourceBoard,
        jobUrl,
        status,
        tier,
        matchScore,
        appliedAt,
        responseReceivedAt,
        rawJson,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<CachedJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_title')) {
      context.handle(_jobTitleMeta,
          jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta));
    } else if (isInserting) {
      context.missing(_jobTitleMeta);
    }
    if (data.containsKey('company')) {
      context.handle(_companyMeta,
          company.isAcceptableOrUnknown(data['company']!, _companyMeta));
    } else if (isInserting) {
      context.missing(_companyMeta);
    }
    if (data.containsKey('source_board')) {
      context.handle(
          _sourceBoardMeta,
          sourceBoard.isAcceptableOrUnknown(
              data['source_board']!, _sourceBoardMeta));
    } else if (isInserting) {
      context.missing(_sourceBoardMeta);
    }
    if (data.containsKey('job_url')) {
      context.handle(_jobUrlMeta,
          jobUrl.isAcceptableOrUnknown(data['job_url']!, _jobUrlMeta));
    } else if (isInserting) {
      context.missing(_jobUrlMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('tier')) {
      context.handle(
          _tierMeta, tier.isAcceptableOrUnknown(data['tier']!, _tierMeta));
    }
    if (data.containsKey('match_score')) {
      context.handle(
          _matchScoreMeta,
          matchScore.isAcceptableOrUnknown(
              data['match_score']!, _matchScoreMeta));
    }
    if (data.containsKey('applied_at')) {
      context.handle(_appliedAtMeta,
          appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta));
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    if (data.containsKey('response_received_at')) {
      context.handle(
          _responseReceivedAtMeta,
          responseReceivedAt.isAcceptableOrUnknown(
              data['response_received_at']!, _responseReceivedAtMeta));
    }
    if (data.containsKey('raw_json')) {
      context.handle(_rawJsonMeta,
          rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta));
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      jobTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_title'])!,
      company: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}company'])!,
      sourceBoard: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_board'])!,
      jobUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_url'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      tier: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tier']),
      matchScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}match_score']),
      appliedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}applied_at'])!,
      responseReceivedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}response_received_at']),
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedJobsTable createAlias(String alias) {
    return $CachedJobsTable(attachedDatabase, alias);
  }
}

class CachedJob extends DataClass implements Insertable<CachedJob> {
  final String id;
  final String jobTitle;
  final String company;
  final String sourceBoard;
  final String jobUrl;
  final String status;
  final int? tier;
  final double? matchScore;
  final DateTime appliedAt;
  final DateTime? responseReceivedAt;
  final String rawJson;
  final DateTime cachedAt;
  const CachedJob(
      {required this.id,
      required this.jobTitle,
      required this.company,
      required this.sourceBoard,
      required this.jobUrl,
      required this.status,
      this.tier,
      this.matchScore,
      required this.appliedAt,
      this.responseReceivedAt,
      required this.rawJson,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_title'] = Variable<String>(jobTitle);
    map['company'] = Variable<String>(company);
    map['source_board'] = Variable<String>(sourceBoard);
    map['job_url'] = Variable<String>(jobUrl);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || tier != null) {
      map['tier'] = Variable<int>(tier);
    }
    if (!nullToAbsent || matchScore != null) {
      map['match_score'] = Variable<double>(matchScore);
    }
    map['applied_at'] = Variable<DateTime>(appliedAt);
    if (!nullToAbsent || responseReceivedAt != null) {
      map['response_received_at'] = Variable<DateTime>(responseReceivedAt);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedJobsCompanion toCompanion(bool nullToAbsent) {
    return CachedJobsCompanion(
      id: Value(id),
      jobTitle: Value(jobTitle),
      company: Value(company),
      sourceBoard: Value(sourceBoard),
      jobUrl: Value(jobUrl),
      status: Value(status),
      tier: tier == null && nullToAbsent ? const Value.absent() : Value(tier),
      matchScore: matchScore == null && nullToAbsent
          ? const Value.absent()
          : Value(matchScore),
      appliedAt: Value(appliedAt),
      responseReceivedAt: responseReceivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(responseReceivedAt),
      rawJson: Value(rawJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedJob(
      id: serializer.fromJson<String>(json['id']),
      jobTitle: serializer.fromJson<String>(json['jobTitle']),
      company: serializer.fromJson<String>(json['company']),
      sourceBoard: serializer.fromJson<String>(json['sourceBoard']),
      jobUrl: serializer.fromJson<String>(json['jobUrl']),
      status: serializer.fromJson<String>(json['status']),
      tier: serializer.fromJson<int?>(json['tier']),
      matchScore: serializer.fromJson<double?>(json['matchScore']),
      appliedAt: serializer.fromJson<DateTime>(json['appliedAt']),
      responseReceivedAt:
          serializer.fromJson<DateTime?>(json['responseReceivedAt']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobTitle': serializer.toJson<String>(jobTitle),
      'company': serializer.toJson<String>(company),
      'sourceBoard': serializer.toJson<String>(sourceBoard),
      'jobUrl': serializer.toJson<String>(jobUrl),
      'status': serializer.toJson<String>(status),
      'tier': serializer.toJson<int?>(tier),
      'matchScore': serializer.toJson<double?>(matchScore),
      'appliedAt': serializer.toJson<DateTime>(appliedAt),
      'responseReceivedAt': serializer.toJson<DateTime?>(responseReceivedAt),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedJob copyWith(
          {String? id,
          String? jobTitle,
          String? company,
          String? sourceBoard,
          String? jobUrl,
          String? status,
          Value<int?> tier = const Value.absent(),
          Value<double?> matchScore = const Value.absent(),
          DateTime? appliedAt,
          Value<DateTime?> responseReceivedAt = const Value.absent(),
          String? rawJson,
          DateTime? cachedAt}) =>
      CachedJob(
        id: id ?? this.id,
        jobTitle: jobTitle ?? this.jobTitle,
        company: company ?? this.company,
        sourceBoard: sourceBoard ?? this.sourceBoard,
        jobUrl: jobUrl ?? this.jobUrl,
        status: status ?? this.status,
        tier: tier.present ? tier.value : this.tier,
        matchScore: matchScore.present ? matchScore.value : this.matchScore,
        appliedAt: appliedAt ?? this.appliedAt,
        responseReceivedAt: responseReceivedAt.present
            ? responseReceivedAt.value
            : this.responseReceivedAt,
        rawJson: rawJson ?? this.rawJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedJob copyWithCompanion(CachedJobsCompanion data) {
    return CachedJob(
      id: data.id.present ? data.id.value : this.id,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
      company: data.company.present ? data.company.value : this.company,
      sourceBoard:
          data.sourceBoard.present ? data.sourceBoard.value : this.sourceBoard,
      jobUrl: data.jobUrl.present ? data.jobUrl.value : this.jobUrl,
      status: data.status.present ? data.status.value : this.status,
      tier: data.tier.present ? data.tier.value : this.tier,
      matchScore:
          data.matchScore.present ? data.matchScore.value : this.matchScore,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      responseReceivedAt: data.responseReceivedAt.present
          ? data.responseReceivedAt.value
          : this.responseReceivedAt,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedJob(')
          ..write('id: $id, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('company: $company, ')
          ..write('sourceBoard: $sourceBoard, ')
          ..write('jobUrl: $jobUrl, ')
          ..write('status: $status, ')
          ..write('tier: $tier, ')
          ..write('matchScore: $matchScore, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('responseReceivedAt: $responseReceivedAt, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      jobTitle,
      company,
      sourceBoard,
      jobUrl,
      status,
      tier,
      matchScore,
      appliedAt,
      responseReceivedAt,
      rawJson,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedJob &&
          other.id == this.id &&
          other.jobTitle == this.jobTitle &&
          other.company == this.company &&
          other.sourceBoard == this.sourceBoard &&
          other.jobUrl == this.jobUrl &&
          other.status == this.status &&
          other.tier == this.tier &&
          other.matchScore == this.matchScore &&
          other.appliedAt == this.appliedAt &&
          other.responseReceivedAt == this.responseReceivedAt &&
          other.rawJson == this.rawJson &&
          other.cachedAt == this.cachedAt);
}

class CachedJobsCompanion extends UpdateCompanion<CachedJob> {
  final Value<String> id;
  final Value<String> jobTitle;
  final Value<String> company;
  final Value<String> sourceBoard;
  final Value<String> jobUrl;
  final Value<String> status;
  final Value<int?> tier;
  final Value<double?> matchScore;
  final Value<DateTime> appliedAt;
  final Value<DateTime?> responseReceivedAt;
  final Value<String> rawJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedJobsCompanion({
    this.id = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.company = const Value.absent(),
    this.sourceBoard = const Value.absent(),
    this.jobUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.tier = const Value.absent(),
    this.matchScore = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.responseReceivedAt = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedJobsCompanion.insert({
    required String id,
    required String jobTitle,
    required String company,
    required String sourceBoard,
    required String jobUrl,
    this.status = const Value.absent(),
    this.tier = const Value.absent(),
    this.matchScore = const Value.absent(),
    required DateTime appliedAt,
    this.responseReceivedAt = const Value.absent(),
    required String rawJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        jobTitle = Value(jobTitle),
        company = Value(company),
        sourceBoard = Value(sourceBoard),
        jobUrl = Value(jobUrl),
        appliedAt = Value(appliedAt),
        rawJson = Value(rawJson),
        cachedAt = Value(cachedAt);
  static Insertable<CachedJob> custom({
    Expression<String>? id,
    Expression<String>? jobTitle,
    Expression<String>? company,
    Expression<String>? sourceBoard,
    Expression<String>? jobUrl,
    Expression<String>? status,
    Expression<int>? tier,
    Expression<double>? matchScore,
    Expression<DateTime>? appliedAt,
    Expression<DateTime>? responseReceivedAt,
    Expression<String>? rawJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobTitle != null) 'job_title': jobTitle,
      if (company != null) 'company': company,
      if (sourceBoard != null) 'source_board': sourceBoard,
      if (jobUrl != null) 'job_url': jobUrl,
      if (status != null) 'status': status,
      if (tier != null) 'tier': tier,
      if (matchScore != null) 'match_score': matchScore,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (responseReceivedAt != null)
        'response_received_at': responseReceivedAt,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedJobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? jobTitle,
      Value<String>? company,
      Value<String>? sourceBoard,
      Value<String>? jobUrl,
      Value<String>? status,
      Value<int?>? tier,
      Value<double?>? matchScore,
      Value<DateTime>? appliedAt,
      Value<DateTime?>? responseReceivedAt,
      Value<String>? rawJson,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedJobsCompanion(
      id: id ?? this.id,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      sourceBoard: sourceBoard ?? this.sourceBoard,
      jobUrl: jobUrl ?? this.jobUrl,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      matchScore: matchScore ?? this.matchScore,
      appliedAt: appliedAt ?? this.appliedAt,
      responseReceivedAt: responseReceivedAt ?? this.responseReceivedAt,
      rawJson: rawJson ?? this.rawJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (sourceBoard.present) {
      map['source_board'] = Variable<String>(sourceBoard.value);
    }
    if (jobUrl.present) {
      map['job_url'] = Variable<String>(jobUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (tier.present) {
      map['tier'] = Variable<int>(tier.value);
    }
    if (matchScore.present) {
      map['match_score'] = Variable<double>(matchScore.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    if (responseReceivedAt.present) {
      map['response_received_at'] =
          Variable<DateTime>(responseReceivedAt.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedJobsCompanion(')
          ..write('id: $id, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('company: $company, ')
          ..write('sourceBoard: $sourceBoard, ')
          ..write('jobUrl: $jobUrl, ')
          ..write('status: $status, ')
          ..write('tier: $tier, ')
          ..write('matchScore: $matchScore, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('responseReceivedAt: $responseReceivedAt, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedEmailBodiesTable extends CachedEmailBodies
    with TableInfo<$CachedEmailBodiesTable, CachedEmailBody> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedEmailBodiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resendIdMeta =
      const VerificationMeta('resendId');
  @override
  late final GeneratedColumn<String> resendId = GeneratedColumn<String>(
      'resend_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _directionMeta =
      const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
      'direction', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyHtmlMeta =
      const VerificationMeta('bodyHtml');
  @override
  late final GeneratedColumn<String> bodyHtml = GeneratedColumn<String>(
      'body_html', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyTextMeta =
      const VerificationMeta('bodyText');
  @override
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
      'body_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rawJsonMeta =
      const VerificationMeta('rawJson');
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
      'raw_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [resendId, direction, bodyHtml, bodyText, rawJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_email_bodies';
  @override
  VerificationContext validateIntegrity(Insertable<CachedEmailBody> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resend_id')) {
      context.handle(_resendIdMeta,
          resendId.isAcceptableOrUnknown(data['resend_id']!, _resendIdMeta));
    } else if (isInserting) {
      context.missing(_resendIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta,
          direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('body_html')) {
      context.handle(_bodyHtmlMeta,
          bodyHtml.isAcceptableOrUnknown(data['body_html']!, _bodyHtmlMeta));
    }
    if (data.containsKey('body_text')) {
      context.handle(_bodyTextMeta,
          bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta));
    }
    if (data.containsKey('raw_json')) {
      context.handle(_rawJsonMeta,
          rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta));
    } else if (isInserting) {
      context.missing(_rawJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resendId};
  @override
  CachedEmailBody map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedEmailBody(
      resendId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resend_id'])!,
      direction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      bodyHtml: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_html']),
      bodyText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_text']),
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $CachedEmailBodiesTable createAlias(String alias) {
    return $CachedEmailBodiesTable(attachedDatabase, alias);
  }
}

class CachedEmailBody extends DataClass implements Insertable<CachedEmailBody> {
  final String resendId;
  final String direction;
  final String? bodyHtml;
  final String? bodyText;
  final String rawJson;
  final DateTime fetchedAt;
  const CachedEmailBody(
      {required this.resendId,
      required this.direction,
      this.bodyHtml,
      this.bodyText,
      required this.rawJson,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resend_id'] = Variable<String>(resendId);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || bodyHtml != null) {
      map['body_html'] = Variable<String>(bodyHtml);
    }
    if (!nullToAbsent || bodyText != null) {
      map['body_text'] = Variable<String>(bodyText);
    }
    map['raw_json'] = Variable<String>(rawJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedEmailBodiesCompanion toCompanion(bool nullToAbsent) {
    return CachedEmailBodiesCompanion(
      resendId: Value(resendId),
      direction: Value(direction),
      bodyHtml: bodyHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyHtml),
      bodyText: bodyText == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyText),
      rawJson: Value(rawJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedEmailBody.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedEmailBody(
      resendId: serializer.fromJson<String>(json['resendId']),
      direction: serializer.fromJson<String>(json['direction']),
      bodyHtml: serializer.fromJson<String?>(json['bodyHtml']),
      bodyText: serializer.fromJson<String?>(json['bodyText']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resendId': serializer.toJson<String>(resendId),
      'direction': serializer.toJson<String>(direction),
      'bodyHtml': serializer.toJson<String?>(bodyHtml),
      'bodyText': serializer.toJson<String?>(bodyText),
      'rawJson': serializer.toJson<String>(rawJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedEmailBody copyWith(
          {String? resendId,
          String? direction,
          Value<String?> bodyHtml = const Value.absent(),
          Value<String?> bodyText = const Value.absent(),
          String? rawJson,
          DateTime? fetchedAt}) =>
      CachedEmailBody(
        resendId: resendId ?? this.resendId,
        direction: direction ?? this.direction,
        bodyHtml: bodyHtml.present ? bodyHtml.value : this.bodyHtml,
        bodyText: bodyText.present ? bodyText.value : this.bodyText,
        rawJson: rawJson ?? this.rawJson,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  CachedEmailBody copyWithCompanion(CachedEmailBodiesCompanion data) {
    return CachedEmailBody(
      resendId: data.resendId.present ? data.resendId.value : this.resendId,
      direction: data.direction.present ? data.direction.value : this.direction,
      bodyHtml: data.bodyHtml.present ? data.bodyHtml.value : this.bodyHtml,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedEmailBody(')
          ..write('resendId: $resendId, ')
          ..write('direction: $direction, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('bodyText: $bodyText, ')
          ..write('rawJson: $rawJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(resendId, direction, bodyHtml, bodyText, rawJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedEmailBody &&
          other.resendId == this.resendId &&
          other.direction == this.direction &&
          other.bodyHtml == this.bodyHtml &&
          other.bodyText == this.bodyText &&
          other.rawJson == this.rawJson &&
          other.fetchedAt == this.fetchedAt);
}

class CachedEmailBodiesCompanion extends UpdateCompanion<CachedEmailBody> {
  final Value<String> resendId;
  final Value<String> direction;
  final Value<String?> bodyHtml;
  final Value<String?> bodyText;
  final Value<String> rawJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedEmailBodiesCompanion({
    this.resendId = const Value.absent(),
    this.direction = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedEmailBodiesCompanion.insert({
    required String resendId,
    required String direction,
    this.bodyHtml = const Value.absent(),
    this.bodyText = const Value.absent(),
    required String rawJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : resendId = Value(resendId),
        direction = Value(direction),
        rawJson = Value(rawJson),
        fetchedAt = Value(fetchedAt);
  static Insertable<CachedEmailBody> custom({
    Expression<String>? resendId,
    Expression<String>? direction,
    Expression<String>? bodyHtml,
    Expression<String>? bodyText,
    Expression<String>? rawJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resendId != null) 'resend_id': resendId,
      if (direction != null) 'direction': direction,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (bodyText != null) 'body_text': bodyText,
      if (rawJson != null) 'raw_json': rawJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedEmailBodiesCompanion copyWith(
      {Value<String>? resendId,
      Value<String>? direction,
      Value<String?>? bodyHtml,
      Value<String?>? bodyText,
      Value<String>? rawJson,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return CachedEmailBodiesCompanion(
      resendId: resendId ?? this.resendId,
      direction: direction ?? this.direction,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      bodyText: bodyText ?? this.bodyText,
      rawJson: rawJson ?? this.rawJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resendId.present) {
      map['resend_id'] = Variable<String>(resendId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (bodyHtml.present) {
      map['body_html'] = Variable<String>(bodyHtml.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedEmailBodiesCompanion(')
          ..write('resendId: $resendId, ')
          ..write('direction: $direction, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('bodyText: $bodyText, ')
          ..write('rawJson: $rawJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDraftsTable extends LocalDrafts
    with TableInfo<$LocalDraftsTable, LocalDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: _uuid);
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
      'job_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _replyToResendIdMeta =
      const VerificationMeta('replyToResendId');
  @override
  late final GeneratedColumn<String> replyToResendId = GeneratedColumn<String>(
      'reply_to_resend_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toAddressesMeta =
      const VerificationMeta('toAddresses');
  @override
  late final GeneratedColumn<String> toAddresses = GeneratedColumn<String>(
      'to_addresses', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ccAddressesMeta =
      const VerificationMeta('ccAddresses');
  @override
  late final GeneratedColumn<String> ccAddresses = GeneratedColumn<String>(
      'cc_addresses', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bccAddressesMeta =
      const VerificationMeta('bccAddresses');
  @override
  late final GeneratedColumn<String> bccAddresses = GeneratedColumn<String>(
      'bcc_addresses', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _replyToMeta =
      const VerificationMeta('replyTo');
  @override
  late final GeneratedColumn<String> replyTo = GeneratedColumn<String>(
      'reply_to', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyHtmlMeta =
      const VerificationMeta('bodyHtml');
  @override
  late final GeneratedColumn<String> bodyHtml = GeneratedColumn<String>(
      'body_html', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bodyTextMeta =
      const VerificationMeta('bodyText');
  @override
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
      'body_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('dirty'));
  static const VerificationMeta _sentResendIdMeta =
      const VerificationMeta('sentResendId');
  @override
  late final GeneratedColumn<String> sentResendId = GeneratedColumn<String>(
      'sent_resend_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
      'sent_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        remoteId,
        jobId,
        replyToResendId,
        toAddresses,
        ccAddresses,
        bccAddresses,
        replyTo,
        subject,
        bodyHtml,
        bodyText,
        syncState,
        sentResendId,
        sentAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_drafts';
  @override
  VerificationContext validateIntegrity(Insertable<LocalDraft> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
          _jobIdMeta, jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta));
    }
    if (data.containsKey('reply_to_resend_id')) {
      context.handle(
          _replyToResendIdMeta,
          replyToResendId.isAcceptableOrUnknown(
              data['reply_to_resend_id']!, _replyToResendIdMeta));
    }
    if (data.containsKey('to_addresses')) {
      context.handle(
          _toAddressesMeta,
          toAddresses.isAcceptableOrUnknown(
              data['to_addresses']!, _toAddressesMeta));
    } else if (isInserting) {
      context.missing(_toAddressesMeta);
    }
    if (data.containsKey('cc_addresses')) {
      context.handle(
          _ccAddressesMeta,
          ccAddresses.isAcceptableOrUnknown(
              data['cc_addresses']!, _ccAddressesMeta));
    }
    if (data.containsKey('bcc_addresses')) {
      context.handle(
          _bccAddressesMeta,
          bccAddresses.isAcceptableOrUnknown(
              data['bcc_addresses']!, _bccAddressesMeta));
    }
    if (data.containsKey('reply_to')) {
      context.handle(_replyToMeta,
          replyTo.isAcceptableOrUnknown(data['reply_to']!, _replyToMeta));
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    }
    if (data.containsKey('body_html')) {
      context.handle(_bodyHtmlMeta,
          bodyHtml.isAcceptableOrUnknown(data['body_html']!, _bodyHtmlMeta));
    }
    if (data.containsKey('body_text')) {
      context.handle(_bodyTextMeta,
          bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta));
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('sent_resend_id')) {
      context.handle(
          _sentResendIdMeta,
          sentResendId.isAcceptableOrUnknown(
              data['sent_resend_id']!, _sentResendIdMeta));
    }
    if (data.containsKey('sent_at')) {
      context.handle(_sentAtMeta,
          sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDraft(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_id']),
      jobId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_id']),
      replyToResendId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}reply_to_resend_id']),
      toAddresses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_addresses'])!,
      ccAddresses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cc_addresses']),
      bccAddresses: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bcc_addresses']),
      replyTo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reply_to']),
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject']),
      bodyHtml: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_html']),
      bodyText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body_text']),
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      sentResendId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sent_resend_id']),
      sentAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}sent_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalDraftsTable createAlias(String alias) {
    return $LocalDraftsTable(attachedDatabase, alias);
  }
}

class LocalDraft extends DataClass implements Insertable<LocalDraft> {
  final String localId;
  final String? remoteId;
  final String? jobId;
  final String? replyToResendId;
  final String toAddresses;
  final String? ccAddresses;
  final String? bccAddresses;
  final String? replyTo;
  final String? subject;
  final String? bodyHtml;
  final String? bodyText;
  final String syncState;
  final String? sentResendId;
  final DateTime? sentAt;
  final DateTime updatedAt;
  const LocalDraft(
      {required this.localId,
      this.remoteId,
      this.jobId,
      this.replyToResendId,
      required this.toAddresses,
      this.ccAddresses,
      this.bccAddresses,
      this.replyTo,
      this.subject,
      this.bodyHtml,
      this.bodyText,
      required this.syncState,
      this.sentResendId,
      this.sentAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    if (!nullToAbsent || replyToResendId != null) {
      map['reply_to_resend_id'] = Variable<String>(replyToResendId);
    }
    map['to_addresses'] = Variable<String>(toAddresses);
    if (!nullToAbsent || ccAddresses != null) {
      map['cc_addresses'] = Variable<String>(ccAddresses);
    }
    if (!nullToAbsent || bccAddresses != null) {
      map['bcc_addresses'] = Variable<String>(bccAddresses);
    }
    if (!nullToAbsent || replyTo != null) {
      map['reply_to'] = Variable<String>(replyTo);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || bodyHtml != null) {
      map['body_html'] = Variable<String>(bodyHtml);
    }
    if (!nullToAbsent || bodyText != null) {
      map['body_text'] = Variable<String>(bodyText);
    }
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || sentResendId != null) {
      map['sent_resend_id'] = Variable<String>(sentResendId);
    }
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDraftsCompanion toCompanion(bool nullToAbsent) {
    return LocalDraftsCompanion(
      localId: Value(localId),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      jobId:
          jobId == null && nullToAbsent ? const Value.absent() : Value(jobId),
      replyToResendId: replyToResendId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToResendId),
      toAddresses: Value(toAddresses),
      ccAddresses: ccAddresses == null && nullToAbsent
          ? const Value.absent()
          : Value(ccAddresses),
      bccAddresses: bccAddresses == null && nullToAbsent
          ? const Value.absent()
          : Value(bccAddresses),
      replyTo: replyTo == null && nullToAbsent
          ? const Value.absent()
          : Value(replyTo),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      bodyHtml: bodyHtml == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyHtml),
      bodyText: bodyText == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyText),
      syncState: Value(syncState),
      sentResendId: sentResendId == null && nullToAbsent
          ? const Value.absent()
          : Value(sentResendId),
      sentAt:
          sentAt == null && nullToAbsent ? const Value.absent() : Value(sentAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDraft.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDraft(
      localId: serializer.fromJson<String>(json['localId']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      replyToResendId: serializer.fromJson<String?>(json['replyToResendId']),
      toAddresses: serializer.fromJson<String>(json['toAddresses']),
      ccAddresses: serializer.fromJson<String?>(json['ccAddresses']),
      bccAddresses: serializer.fromJson<String?>(json['bccAddresses']),
      replyTo: serializer.fromJson<String?>(json['replyTo']),
      subject: serializer.fromJson<String?>(json['subject']),
      bodyHtml: serializer.fromJson<String?>(json['bodyHtml']),
      bodyText: serializer.fromJson<String?>(json['bodyText']),
      syncState: serializer.fromJson<String>(json['syncState']),
      sentResendId: serializer.fromJson<String?>(json['sentResendId']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'remoteId': serializer.toJson<String?>(remoteId),
      'jobId': serializer.toJson<String?>(jobId),
      'replyToResendId': serializer.toJson<String?>(replyToResendId),
      'toAddresses': serializer.toJson<String>(toAddresses),
      'ccAddresses': serializer.toJson<String?>(ccAddresses),
      'bccAddresses': serializer.toJson<String?>(bccAddresses),
      'replyTo': serializer.toJson<String?>(replyTo),
      'subject': serializer.toJson<String?>(subject),
      'bodyHtml': serializer.toJson<String?>(bodyHtml),
      'bodyText': serializer.toJson<String?>(bodyText),
      'syncState': serializer.toJson<String>(syncState),
      'sentResendId': serializer.toJson<String?>(sentResendId),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDraft copyWith(
          {String? localId,
          Value<String?> remoteId = const Value.absent(),
          Value<String?> jobId = const Value.absent(),
          Value<String?> replyToResendId = const Value.absent(),
          String? toAddresses,
          Value<String?> ccAddresses = const Value.absent(),
          Value<String?> bccAddresses = const Value.absent(),
          Value<String?> replyTo = const Value.absent(),
          Value<String?> subject = const Value.absent(),
          Value<String?> bodyHtml = const Value.absent(),
          Value<String?> bodyText = const Value.absent(),
          String? syncState,
          Value<String?> sentResendId = const Value.absent(),
          Value<DateTime?> sentAt = const Value.absent(),
          DateTime? updatedAt}) =>
      LocalDraft(
        localId: localId ?? this.localId,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        jobId: jobId.present ? jobId.value : this.jobId,
        replyToResendId: replyToResendId.present
            ? replyToResendId.value
            : this.replyToResendId,
        toAddresses: toAddresses ?? this.toAddresses,
        ccAddresses: ccAddresses.present ? ccAddresses.value : this.ccAddresses,
        bccAddresses:
            bccAddresses.present ? bccAddresses.value : this.bccAddresses,
        replyTo: replyTo.present ? replyTo.value : this.replyTo,
        subject: subject.present ? subject.value : this.subject,
        bodyHtml: bodyHtml.present ? bodyHtml.value : this.bodyHtml,
        bodyText: bodyText.present ? bodyText.value : this.bodyText,
        syncState: syncState ?? this.syncState,
        sentResendId:
            sentResendId.present ? sentResendId.value : this.sentResendId,
        sentAt: sentAt.present ? sentAt.value : this.sentAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalDraft copyWithCompanion(LocalDraftsCompanion data) {
    return LocalDraft(
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      replyToResendId: data.replyToResendId.present
          ? data.replyToResendId.value
          : this.replyToResendId,
      toAddresses:
          data.toAddresses.present ? data.toAddresses.value : this.toAddresses,
      ccAddresses:
          data.ccAddresses.present ? data.ccAddresses.value : this.ccAddresses,
      bccAddresses: data.bccAddresses.present
          ? data.bccAddresses.value
          : this.bccAddresses,
      replyTo: data.replyTo.present ? data.replyTo.value : this.replyTo,
      subject: data.subject.present ? data.subject.value : this.subject,
      bodyHtml: data.bodyHtml.present ? data.bodyHtml.value : this.bodyHtml,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      sentResendId: data.sentResendId.present
          ? data.sentResendId.value
          : this.sentResendId,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraft(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('jobId: $jobId, ')
          ..write('replyToResendId: $replyToResendId, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('bccAddresses: $bccAddresses, ')
          ..write('replyTo: $replyTo, ')
          ..write('subject: $subject, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('bodyText: $bodyText, ')
          ..write('syncState: $syncState, ')
          ..write('sentResendId: $sentResendId, ')
          ..write('sentAt: $sentAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId,
      remoteId,
      jobId,
      replyToResendId,
      toAddresses,
      ccAddresses,
      bccAddresses,
      replyTo,
      subject,
      bodyHtml,
      bodyText,
      syncState,
      sentResendId,
      sentAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDraft &&
          other.localId == this.localId &&
          other.remoteId == this.remoteId &&
          other.jobId == this.jobId &&
          other.replyToResendId == this.replyToResendId &&
          other.toAddresses == this.toAddresses &&
          other.ccAddresses == this.ccAddresses &&
          other.bccAddresses == this.bccAddresses &&
          other.replyTo == this.replyTo &&
          other.subject == this.subject &&
          other.bodyHtml == this.bodyHtml &&
          other.bodyText == this.bodyText &&
          other.syncState == this.syncState &&
          other.sentResendId == this.sentResendId &&
          other.sentAt == this.sentAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDraftsCompanion extends UpdateCompanion<LocalDraft> {
  final Value<String> localId;
  final Value<String?> remoteId;
  final Value<String?> jobId;
  final Value<String?> replyToResendId;
  final Value<String> toAddresses;
  final Value<String?> ccAddresses;
  final Value<String?> bccAddresses;
  final Value<String?> replyTo;
  final Value<String?> subject;
  final Value<String?> bodyHtml;
  final Value<String?> bodyText;
  final Value<String> syncState;
  final Value<String?> sentResendId;
  final Value<DateTime?> sentAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalDraftsCompanion({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.replyToResendId = const Value.absent(),
    this.toAddresses = const Value.absent(),
    this.ccAddresses = const Value.absent(),
    this.bccAddresses = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.subject = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.syncState = const Value.absent(),
    this.sentResendId = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDraftsCompanion.insert({
    this.localId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.jobId = const Value.absent(),
    this.replyToResendId = const Value.absent(),
    required String toAddresses,
    this.ccAddresses = const Value.absent(),
    this.bccAddresses = const Value.absent(),
    this.replyTo = const Value.absent(),
    this.subject = const Value.absent(),
    this.bodyHtml = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.syncState = const Value.absent(),
    this.sentResendId = const Value.absent(),
    this.sentAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : toAddresses = Value(toAddresses),
        updatedAt = Value(updatedAt);
  static Insertable<LocalDraft> custom({
    Expression<String>? localId,
    Expression<String>? remoteId,
    Expression<String>? jobId,
    Expression<String>? replyToResendId,
    Expression<String>? toAddresses,
    Expression<String>? ccAddresses,
    Expression<String>? bccAddresses,
    Expression<String>? replyTo,
    Expression<String>? subject,
    Expression<String>? bodyHtml,
    Expression<String>? bodyText,
    Expression<String>? syncState,
    Expression<String>? sentResendId,
    Expression<DateTime>? sentAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (remoteId != null) 'remote_id': remoteId,
      if (jobId != null) 'job_id': jobId,
      if (replyToResendId != null) 'reply_to_resend_id': replyToResendId,
      if (toAddresses != null) 'to_addresses': toAddresses,
      if (ccAddresses != null) 'cc_addresses': ccAddresses,
      if (bccAddresses != null) 'bcc_addresses': bccAddresses,
      if (replyTo != null) 'reply_to': replyTo,
      if (subject != null) 'subject': subject,
      if (bodyHtml != null) 'body_html': bodyHtml,
      if (bodyText != null) 'body_text': bodyText,
      if (syncState != null) 'sync_state': syncState,
      if (sentResendId != null) 'sent_resend_id': sentResendId,
      if (sentAt != null) 'sent_at': sentAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDraftsCompanion copyWith(
      {Value<String>? localId,
      Value<String?>? remoteId,
      Value<String?>? jobId,
      Value<String?>? replyToResendId,
      Value<String>? toAddresses,
      Value<String?>? ccAddresses,
      Value<String?>? bccAddresses,
      Value<String?>? replyTo,
      Value<String?>? subject,
      Value<String?>? bodyHtml,
      Value<String?>? bodyText,
      Value<String>? syncState,
      Value<String?>? sentResendId,
      Value<DateTime?>? sentAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalDraftsCompanion(
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      jobId: jobId ?? this.jobId,
      replyToResendId: replyToResendId ?? this.replyToResendId,
      toAddresses: toAddresses ?? this.toAddresses,
      ccAddresses: ccAddresses ?? this.ccAddresses,
      bccAddresses: bccAddresses ?? this.bccAddresses,
      replyTo: replyTo ?? this.replyTo,
      subject: subject ?? this.subject,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      bodyText: bodyText ?? this.bodyText,
      syncState: syncState ?? this.syncState,
      sentResendId: sentResendId ?? this.sentResendId,
      sentAt: sentAt ?? this.sentAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (replyToResendId.present) {
      map['reply_to_resend_id'] = Variable<String>(replyToResendId.value);
    }
    if (toAddresses.present) {
      map['to_addresses'] = Variable<String>(toAddresses.value);
    }
    if (ccAddresses.present) {
      map['cc_addresses'] = Variable<String>(ccAddresses.value);
    }
    if (bccAddresses.present) {
      map['bcc_addresses'] = Variable<String>(bccAddresses.value);
    }
    if (replyTo.present) {
      map['reply_to'] = Variable<String>(replyTo.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (bodyHtml.present) {
      map['body_html'] = Variable<String>(bodyHtml.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (sentResendId.present) {
      map['sent_resend_id'] = Variable<String>(sentResendId.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDraftsCompanion(')
          ..write('localId: $localId, ')
          ..write('remoteId: $remoteId, ')
          ..write('jobId: $jobId, ')
          ..write('replyToResendId: $replyToResendId, ')
          ..write('toAddresses: $toAddresses, ')
          ..write('ccAddresses: $ccAddresses, ')
          ..write('bccAddresses: $bccAddresses, ')
          ..write('replyTo: $replyTo, ')
          ..write('subject: $subject, ')
          ..write('bodyHtml: $bodyHtml, ')
          ..write('bodyText: $bodyText, ')
          ..write('syncState: $syncState, ')
          ..write('sentResendId: $sentResendId, ')
          ..write('sentAt: $sentAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $CachedJobsTable cachedJobs = $CachedJobsTable(this);
  late final $CachedEmailBodiesTable cachedEmailBodies =
      $CachedEmailBodiesTable(this);
  late final $LocalDraftsTable localDrafts = $LocalDraftsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedJobs, cachedEmailBodies, localDrafts];
}

typedef $$CachedJobsTableCreateCompanionBuilder = CachedJobsCompanion Function({
  required String id,
  required String jobTitle,
  required String company,
  required String sourceBoard,
  required String jobUrl,
  Value<String> status,
  Value<int?> tier,
  Value<double?> matchScore,
  required DateTime appliedAt,
  Value<DateTime?> responseReceivedAt,
  required String rawJson,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedJobsTableUpdateCompanionBuilder = CachedJobsCompanion Function({
  Value<String> id,
  Value<String> jobTitle,
  Value<String> company,
  Value<String> sourceBoard,
  Value<String> jobUrl,
  Value<String> status,
  Value<int?> tier,
  Value<double?> matchScore,
  Value<DateTime> appliedAt,
  Value<DateTime?> responseReceivedAt,
  Value<String> rawJson,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedJobsTableFilterComposer
    extends Composer<_$AppDb, $CachedJobsTable> {
  $$CachedJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobTitle => $composableBuilder(
      column: $table.jobTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceBoard => $composableBuilder(
      column: $table.sourceBoard, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobUrl => $composableBuilder(
      column: $table.jobUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get responseReceivedAt => $composableBuilder(
      column: $table.responseReceivedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedJobsTableOrderingComposer
    extends Composer<_$AppDb, $CachedJobsTable> {
  $$CachedJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobTitle => $composableBuilder(
      column: $table.jobTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get company => $composableBuilder(
      column: $table.company, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceBoard => $composableBuilder(
      column: $table.sourceBoard, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobUrl => $composableBuilder(
      column: $table.jobUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
      column: $table.appliedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get responseReceivedAt => $composableBuilder(
      column: $table.responseReceivedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedJobsTableAnnotationComposer
    extends Composer<_$AppDb, $CachedJobsTable> {
  $$CachedJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobTitle =>
      $composableBuilder(column: $table.jobTitle, builder: (column) => column);

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get sourceBoard => $composableBuilder(
      column: $table.sourceBoard, builder: (column) => column);

  GeneratedColumn<String> get jobUrl =>
      $composableBuilder(column: $table.jobUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<double> get matchScore => $composableBuilder(
      column: $table.matchScore, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get responseReceivedAt => $composableBuilder(
      column: $table.responseReceivedAt, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedJobsTableTableManager extends RootTableManager<
    _$AppDb,
    $CachedJobsTable,
    CachedJob,
    $$CachedJobsTableFilterComposer,
    $$CachedJobsTableOrderingComposer,
    $$CachedJobsTableAnnotationComposer,
    $$CachedJobsTableCreateCompanionBuilder,
    $$CachedJobsTableUpdateCompanionBuilder,
    (CachedJob, BaseReferences<_$AppDb, $CachedJobsTable, CachedJob>),
    CachedJob,
    PrefetchHooks Function()> {
  $$CachedJobsTableTableManager(_$AppDb db, $CachedJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> jobTitle = const Value.absent(),
            Value<String> company = const Value.absent(),
            Value<String> sourceBoard = const Value.absent(),
            Value<String> jobUrl = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> tier = const Value.absent(),
            Value<double?> matchScore = const Value.absent(),
            Value<DateTime> appliedAt = const Value.absent(),
            Value<DateTime?> responseReceivedAt = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedJobsCompanion(
            id: id,
            jobTitle: jobTitle,
            company: company,
            sourceBoard: sourceBoard,
            jobUrl: jobUrl,
            status: status,
            tier: tier,
            matchScore: matchScore,
            appliedAt: appliedAt,
            responseReceivedAt: responseReceivedAt,
            rawJson: rawJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String jobTitle,
            required String company,
            required String sourceBoard,
            required String jobUrl,
            Value<String> status = const Value.absent(),
            Value<int?> tier = const Value.absent(),
            Value<double?> matchScore = const Value.absent(),
            required DateTime appliedAt,
            Value<DateTime?> responseReceivedAt = const Value.absent(),
            required String rawJson,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedJobsCompanion.insert(
            id: id,
            jobTitle: jobTitle,
            company: company,
            sourceBoard: sourceBoard,
            jobUrl: jobUrl,
            status: status,
            tier: tier,
            matchScore: matchScore,
            appliedAt: appliedAt,
            responseReceivedAt: responseReceivedAt,
            rawJson: rawJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedJobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $CachedJobsTable,
    CachedJob,
    $$CachedJobsTableFilterComposer,
    $$CachedJobsTableOrderingComposer,
    $$CachedJobsTableAnnotationComposer,
    $$CachedJobsTableCreateCompanionBuilder,
    $$CachedJobsTableUpdateCompanionBuilder,
    (CachedJob, BaseReferences<_$AppDb, $CachedJobsTable, CachedJob>),
    CachedJob,
    PrefetchHooks Function()>;
typedef $$CachedEmailBodiesTableCreateCompanionBuilder
    = CachedEmailBodiesCompanion Function({
  required String resendId,
  required String direction,
  Value<String?> bodyHtml,
  Value<String?> bodyText,
  required String rawJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$CachedEmailBodiesTableUpdateCompanionBuilder
    = CachedEmailBodiesCompanion Function({
  Value<String> resendId,
  Value<String> direction,
  Value<String?> bodyHtml,
  Value<String?> bodyText,
  Value<String> rawJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$CachedEmailBodiesTableFilterComposer
    extends Composer<_$AppDb, $CachedEmailBodiesTable> {
  $$CachedEmailBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resendId => $composableBuilder(
      column: $table.resendId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyHtml => $composableBuilder(
      column: $table.bodyHtml, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyText => $composableBuilder(
      column: $table.bodyText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedEmailBodiesTableOrderingComposer
    extends Composer<_$AppDb, $CachedEmailBodiesTable> {
  $$CachedEmailBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resendId => $composableBuilder(
      column: $table.resendId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction => $composableBuilder(
      column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyHtml => $composableBuilder(
      column: $table.bodyHtml, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyText => $composableBuilder(
      column: $table.bodyText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
      column: $table.fetchedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedEmailBodiesTableAnnotationComposer
    extends Composer<_$AppDb, $CachedEmailBodiesTable> {
  $$CachedEmailBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resendId =>
      $composableBuilder(column: $table.resendId, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get bodyHtml =>
      $composableBuilder(column: $table.bodyHtml, builder: (column) => column);

  GeneratedColumn<String> get bodyText =>
      $composableBuilder(column: $table.bodyText, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedEmailBodiesTableTableManager extends RootTableManager<
    _$AppDb,
    $CachedEmailBodiesTable,
    CachedEmailBody,
    $$CachedEmailBodiesTableFilterComposer,
    $$CachedEmailBodiesTableOrderingComposer,
    $$CachedEmailBodiesTableAnnotationComposer,
    $$CachedEmailBodiesTableCreateCompanionBuilder,
    $$CachedEmailBodiesTableUpdateCompanionBuilder,
    (
      CachedEmailBody,
      BaseReferences<_$AppDb, $CachedEmailBodiesTable, CachedEmailBody>
    ),
    CachedEmailBody,
    PrefetchHooks Function()> {
  $$CachedEmailBodiesTableTableManager(
      _$AppDb db, $CachedEmailBodiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedEmailBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedEmailBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedEmailBodiesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> resendId = const Value.absent(),
            Value<String> direction = const Value.absent(),
            Value<String?> bodyHtml = const Value.absent(),
            Value<String?> bodyText = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEmailBodiesCompanion(
            resendId: resendId,
            direction: direction,
            bodyHtml: bodyHtml,
            bodyText: bodyText,
            rawJson: rawJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String resendId,
            required String direction,
            Value<String?> bodyHtml = const Value.absent(),
            Value<String?> bodyText = const Value.absent(),
            required String rawJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedEmailBodiesCompanion.insert(
            resendId: resendId,
            direction: direction,
            bodyHtml: bodyHtml,
            bodyText: bodyText,
            rawJson: rawJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedEmailBodiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $CachedEmailBodiesTable,
    CachedEmailBody,
    $$CachedEmailBodiesTableFilterComposer,
    $$CachedEmailBodiesTableOrderingComposer,
    $$CachedEmailBodiesTableAnnotationComposer,
    $$CachedEmailBodiesTableCreateCompanionBuilder,
    $$CachedEmailBodiesTableUpdateCompanionBuilder,
    (
      CachedEmailBody,
      BaseReferences<_$AppDb, $CachedEmailBodiesTable, CachedEmailBody>
    ),
    CachedEmailBody,
    PrefetchHooks Function()>;
typedef $$LocalDraftsTableCreateCompanionBuilder = LocalDraftsCompanion
    Function({
  Value<String> localId,
  Value<String?> remoteId,
  Value<String?> jobId,
  Value<String?> replyToResendId,
  required String toAddresses,
  Value<String?> ccAddresses,
  Value<String?> bccAddresses,
  Value<String?> replyTo,
  Value<String?> subject,
  Value<String?> bodyHtml,
  Value<String?> bodyText,
  Value<String> syncState,
  Value<String?> sentResendId,
  Value<DateTime?> sentAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalDraftsTableUpdateCompanionBuilder = LocalDraftsCompanion
    Function({
  Value<String> localId,
  Value<String?> remoteId,
  Value<String?> jobId,
  Value<String?> replyToResendId,
  Value<String> toAddresses,
  Value<String?> ccAddresses,
  Value<String?> bccAddresses,
  Value<String?> replyTo,
  Value<String?> subject,
  Value<String?> bodyHtml,
  Value<String?> bodyText,
  Value<String> syncState,
  Value<String?> sentResendId,
  Value<DateTime?> sentAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalDraftsTableFilterComposer
    extends Composer<_$AppDb, $LocalDraftsTable> {
  $$LocalDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyToResendId => $composableBuilder(
      column: $table.replyToResendId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toAddresses => $composableBuilder(
      column: $table.toAddresses, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ccAddresses => $composableBuilder(
      column: $table.ccAddresses, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bccAddresses => $composableBuilder(
      column: $table.bccAddresses, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get replyTo => $composableBuilder(
      column: $table.replyTo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyHtml => $composableBuilder(
      column: $table.bodyHtml, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bodyText => $composableBuilder(
      column: $table.bodyText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentResendId => $composableBuilder(
      column: $table.sentResendId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalDraftsTableOrderingComposer
    extends Composer<_$AppDb, $LocalDraftsTable> {
  $$LocalDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId => $composableBuilder(
      column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobId => $composableBuilder(
      column: $table.jobId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyToResendId => $composableBuilder(
      column: $table.replyToResendId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toAddresses => $composableBuilder(
      column: $table.toAddresses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ccAddresses => $composableBuilder(
      column: $table.ccAddresses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bccAddresses => $composableBuilder(
      column: $table.bccAddresses,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get replyTo => $composableBuilder(
      column: $table.replyTo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyHtml => $composableBuilder(
      column: $table.bodyHtml, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bodyText => $composableBuilder(
      column: $table.bodyText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentResendId => $composableBuilder(
      column: $table.sentResendId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
      column: $table.sentAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalDraftsTableAnnotationComposer
    extends Composer<_$AppDb, $LocalDraftsTable> {
  $$LocalDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get replyToResendId => $composableBuilder(
      column: $table.replyToResendId, builder: (column) => column);

  GeneratedColumn<String> get toAddresses => $composableBuilder(
      column: $table.toAddresses, builder: (column) => column);

  GeneratedColumn<String> get ccAddresses => $composableBuilder(
      column: $table.ccAddresses, builder: (column) => column);

  GeneratedColumn<String> get bccAddresses => $composableBuilder(
      column: $table.bccAddresses, builder: (column) => column);

  GeneratedColumn<String> get replyTo =>
      $composableBuilder(column: $table.replyTo, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get bodyHtml =>
      $composableBuilder(column: $table.bodyHtml, builder: (column) => column);

  GeneratedColumn<String> get bodyText =>
      $composableBuilder(column: $table.bodyText, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get sentResendId => $composableBuilder(
      column: $table.sentResendId, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDraftsTableTableManager extends RootTableManager<
    _$AppDb,
    $LocalDraftsTable,
    LocalDraft,
    $$LocalDraftsTableFilterComposer,
    $$LocalDraftsTableOrderingComposer,
    $$LocalDraftsTableAnnotationComposer,
    $$LocalDraftsTableCreateCompanionBuilder,
    $$LocalDraftsTableUpdateCompanionBuilder,
    (LocalDraft, BaseReferences<_$AppDb, $LocalDraftsTable, LocalDraft>),
    LocalDraft,
    PrefetchHooks Function()> {
  $$LocalDraftsTableTableManager(_$AppDb db, $LocalDraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> replyToResendId = const Value.absent(),
            Value<String> toAddresses = const Value.absent(),
            Value<String?> ccAddresses = const Value.absent(),
            Value<String?> bccAddresses = const Value.absent(),
            Value<String?> replyTo = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String?> bodyHtml = const Value.absent(),
            Value<String?> bodyText = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<String?> sentResendId = const Value.absent(),
            Value<DateTime?> sentAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDraftsCompanion(
            localId: localId,
            remoteId: remoteId,
            jobId: jobId,
            replyToResendId: replyToResendId,
            toAddresses: toAddresses,
            ccAddresses: ccAddresses,
            bccAddresses: bccAddresses,
            replyTo: replyTo,
            subject: subject,
            bodyHtml: bodyHtml,
            bodyText: bodyText,
            syncState: syncState,
            sentResendId: sentResendId,
            sentAt: sentAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> remoteId = const Value.absent(),
            Value<String?> jobId = const Value.absent(),
            Value<String?> replyToResendId = const Value.absent(),
            required String toAddresses,
            Value<String?> ccAddresses = const Value.absent(),
            Value<String?> bccAddresses = const Value.absent(),
            Value<String?> replyTo = const Value.absent(),
            Value<String?> subject = const Value.absent(),
            Value<String?> bodyHtml = const Value.absent(),
            Value<String?> bodyText = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<String?> sentResendId = const Value.absent(),
            Value<DateTime?> sentAt = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDraftsCompanion.insert(
            localId: localId,
            remoteId: remoteId,
            jobId: jobId,
            replyToResendId: replyToResendId,
            toAddresses: toAddresses,
            ccAddresses: ccAddresses,
            bccAddresses: bccAddresses,
            replyTo: replyTo,
            subject: subject,
            bodyHtml: bodyHtml,
            bodyText: bodyText,
            syncState: syncState,
            sentResendId: sentResendId,
            sentAt: sentAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalDraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $LocalDraftsTable,
    LocalDraft,
    $$LocalDraftsTableFilterComposer,
    $$LocalDraftsTableOrderingComposer,
    $$LocalDraftsTableAnnotationComposer,
    $$LocalDraftsTableCreateCompanionBuilder,
    $$LocalDraftsTableUpdateCompanionBuilder,
    (LocalDraft, BaseReferences<_$AppDb, $LocalDraftsTable, LocalDraft>),
    LocalDraft,
    PrefetchHooks Function()>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$CachedJobsTableTableManager get cachedJobs =>
      $$CachedJobsTableTableManager(_db, _db.cachedJobs);
  $$CachedEmailBodiesTableTableManager get cachedEmailBodies =>
      $$CachedEmailBodiesTableTableManager(_db, _db.cachedEmailBodies);
  $$LocalDraftsTableTableManager get localDrafts =>
      $$LocalDraftsTableTableManager(_db, _db.localDrafts);
}
