enum PortfolioRecordType {
  certification('certification', 'Certifications'),
  achievement('achievement', 'Achievements');

  const PortfolioRecordType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static PortfolioRecordType fromDatabase(String? value) =>
      PortfolioRecordType.values.firstWhere(
        (type) => type.databaseValue == value,
        orElse: () => PortfolioRecordType.achievement,
      );
}

class PortfolioRecordDraft {
  const PortfolioRecordDraft({
    required this.recordType,
    required this.title,
    this.source = '',
    this.description = '',
    this.achievedOn,
    this.expiresOn,
    this.isPublic = false,
  });

  final PortfolioRecordType recordType;
  final String title;
  final String source;
  final String description;
  final DateTime? achievedOn;
  final DateTime? expiresOn;
  final bool isPublic;

  Map<String, dynamic> toDatabaseFields() => {
    'record_type': recordType.databaseValue,
    'title': title.trim(),
    'source': _nullableText(source),
    'description': description.trim(),
    'achieved_on': _dateOnly(achievedOn),
    'expires_on': recordType == PortfolioRecordType.certification
        ? _dateOnly(expiresOn)
        : null,
    'is_public': isPublic,
  };
}

class PortfolioRecord extends PortfolioRecordDraft {
  const PortfolioRecord({
    required this.id,
    required this.userId,
    required super.recordType,
    required super.title,
    super.source,
    super.description,
    super.achievedOn,
    super.expiresOn,
    super.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PortfolioRecord.fromJson(Map<String, dynamic> json) =>
      PortfolioRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        recordType: PortfolioRecordType.fromDatabase(
          json['record_type'] as String?,
        ),
        title: json['title'] as String? ?? '',
        source: json['source'] as String? ?? '',
        description: json['description'] as String? ?? '',
        achievedOn: _readDate(json['achieved_on']),
        expiresOn: _readDate(json['expires_on']),
        isPublic: json['is_public'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

String? _nullableText(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _dateOnly(DateTime? date) {
  if (date == null) return null;
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  final text = value as String;
  if (text.length == 10) {
    final parts = text.split('-').map(int.parse).toList(growable: false);
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }
  return DateTime.parse(text).toUtc();
}
