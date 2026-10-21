enum EvidenceKind {
  file('file', 'File'),
  url('url', 'Link');

  const EvidenceKind(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static EvidenceKind fromDatabase(String? value) =>
      EvidenceKind.values.firstWhere(
        (kind) => kind.databaseValue == value,
        orElse: () => EvidenceKind.url,
      );
}

enum EvidenceTargetType {
  project('project', 'Project'),
  skill('skill', 'Skill'),
  experience('experience', 'Experience'),
  portfolioRecord('portfolio_record', 'Certification or achievement');

  const EvidenceTargetType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static EvidenceTargetType fromDatabase(String? value) =>
      EvidenceTargetType.values.firstWhere(
        (type) => type.databaseValue == value,
        orElse: () => EvidenceTargetType.project,
      );
}

class EvidenceTarget {
  const EvidenceTarget({
    required this.type,
    required this.id,
    required this.title,
  });

  final EvidenceTargetType type;
  final String id;
  final String title;

  Map<String, dynamic> toDatabaseFields(String evidenceId) => {
    'evidence_id': evidenceId,
    'target_type': type.databaseValue,
    'target_id': id,
  };

  @override
  bool operator ==(Object other) =>
      other is EvidenceTarget && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

class EvidenceDraft {
  const EvidenceDraft.url({
    required this.title,
    required this.sourceUrl,
    this.description = '',
    this.targets = const [],
  }) : kind = EvidenceKind.url,
       fileName = null,
       contentType = null,
       sizeBytes = null,
       storagePath = null;

  const EvidenceDraft.file({
    required this.title,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
    required this.storagePath,
    this.description = '',
    this.targets = const [],
  }) : kind = EvidenceKind.file,
       sourceUrl = null;

  final EvidenceKind kind;
  final String title;
  final String description;
  final String? sourceUrl;
  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
  final String? storagePath;
  final List<EvidenceTarget> targets;

  Map<String, dynamic> toDatabaseFields() => {
    'kind': kind.databaseValue,
    'title': title.trim(),
    'description': description.trim(),
    'source_url': sourceUrl?.trim(),
    'file_name': fileName,
    'content_type': contentType,
    'size_bytes': sizeBytes,
    'storage_path': storagePath,
  };
}

class EvidenceRecord {
  const EvidenceRecord({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.sourceUrl,
    this.fileName,
    this.contentType,
    this.sizeBytes,
    this.storagePath,
    this.targets = const [],
  });

  final String id;
  final String userId;
  final EvidenceKind kind;
  final String title;
  final String description;
  final String? sourceUrl;
  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
  final String? storagePath;
  final List<EvidenceTarget> targets;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EvidenceRecord.fromJson(
    Map<String, dynamic> json, {
    List<EvidenceTarget> targets = const [],
  }) => EvidenceRecord(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    kind: EvidenceKind.fromDatabase(json['kind'] as String?),
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    sourceUrl: json['source_url'] as String?,
    fileName: json['file_name'] as String?,
    contentType: json['content_type'] as String?,
    sizeBytes: (json['size_bytes'] as num?)?.toInt(),
    storagePath: json['storage_path'] as String?,
    targets: targets,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

class EvidenceUrlPolicy {
  const EvidenceUrlPolicy._();

  static Uri? parse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      return null;
    }
    return uri;
  }
}

class EvidenceFilePolicy {
  const EvidenceFilePolicy._();

  static const int maxFileBytes = 50 * 1000 * 1000;
  static String get maxFileLabel => '${(maxFileBytes / 1000000).round()} MB';

  static const Map<String, String> _canonicalMimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'rtf': 'application/rtf',
    'csv': 'text/csv',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
  };

  static const Map<String, Set<String>> _mimeAliasesByExtension = {
    'rtf': {'application/rtf', 'text/rtf'},
    'csv': {'text/csv', 'application/csv'},
    'mp3': {'audio/mpeg', 'audio/mp3'},
    'm4a': {'audio/mp4', 'audio/x-m4a'},
    'wav': {'audio/wav', 'audio/x-wav', 'audio/wave'},
    'ogg': {'audio/ogg', 'application/ogg'},
  };

  static List<String> get allowedExtensions =>
      _canonicalMimeByExtension.keys.toList(growable: false);

  static List<String> get allowedMimeTypes => _canonicalMimeByExtension.entries
      .expand((entry) => _mimeAliasesByExtension[entry.key] ?? {entry.value})
      .toSet()
      .toList(growable: false);

  static String? contentTypeFor(String fileName) {
    final extension = _extension(fileName);
    return _canonicalMimeByExtension[extension];
  }

  static String? validate({
    required String fileName,
    required String? mimeType,
    required int sizeBytes,
  }) {
    final extension = _extension(fileName);
    final expectedMime = _canonicalMimeByExtension[extension];
    if (expectedMime == null) {
      return 'This file type is not supported. Choose a supported image, document, video, or audio file.';
    }
    if (sizeBytes <= 0) return 'This file is empty.';
    if (sizeBytes > maxFileBytes) {
      return 'This file is larger than the ${EvidenceFilePolicy.maxFileLabel} upload limit.';
    }

    final reportedMime = mimeType?.split(';').first.trim().toLowerCase();
    if (reportedMime != null &&
        reportedMime.isNotEmpty &&
        !(_mimeAliasesByExtension[extension] ?? {expectedMime}).contains(
          reportedMime,
        )) {
      return 'The file type does not match its reported format.';
    }
    return null;
  }

  static String _extension(String fileName) {
    final basename = fileName.split(RegExp(r'[/\\]')).last;
    final dotIndex = basename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == basename.length - 1) return '';
    return basename.substring(dotIndex + 1).toLowerCase();
  }
}
