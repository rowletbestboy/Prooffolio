enum ProjectStatus { inProgress, completed, paused }

enum ProjectPublicationStatus { draft, published }

String projectStatusToDatabase(ProjectStatus status) => switch (status) {
  ProjectStatus.inProgress => 'in_progress',
  ProjectStatus.completed => 'completed',
  ProjectStatus.paused => 'paused',
};

ProjectStatus projectStatusFromDatabase(String? value) => switch (value) {
  'completed' => ProjectStatus.completed,
  'paused' => ProjectStatus.paused,
  _ => ProjectStatus.inProgress,
};

class ProjectDraft {
  const ProjectDraft({
    required this.title,
    this.summary = '',
    this.problemStatement = '',
    this.description = '',
    this.keyFeatures = const [],
    this.technologies = const [],
    this.contribution = '',
    this.challenges = '',
    this.lessonsLearned = '',
    this.repositoryUrl = '',
    this.demoUrl = '',
    this.publicationStatus = ProjectPublicationStatus.draft,
    this.startDate,
    this.endDate,
    this.status = ProjectStatus.inProgress,
  });

  final String title;
  final String summary;
  final String problemStatement;
  final String description;
  final List<String> keyFeatures;
  final List<String> technologies;
  final String contribution;
  final String challenges;
  final String lessonsLearned;
  final String repositoryUrl;
  final String demoUrl;
  final ProjectPublicationStatus publicationStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final ProjectStatus status;

  Map<String, dynamic> toDatabaseFields() => {
    'title': title.trim(),
    'summary': summary.trim(),
    'problem_statement': problemStatement.trim(),
    'description': description.trim(),
    'key_features': _cleanList(keyFeatures),
    'technologies': _cleanList(technologies),
    'contribution': contribution.trim(),
    'challenges': challenges.trim(),
    'lessons_learned': lessonsLearned.trim(),
    'repository_url': repositoryUrl.trim().isEmpty
        ? null
        : repositoryUrl.trim(),
    'demo_url': demoUrl.trim().isEmpty ? null : demoUrl.trim(),
    'start_date': _dateOnly(startDate),
    'end_date': _dateOnly(endDate),
    'status': projectStatusToDatabase(status),
    'publication_status': publicationStatus.name,
  };
}

class Project {
  const Project({
    required this.id,
    required this.userId,
    required this.title,
    required this.summary,
    required this.problemStatement,
    required this.description,
    required this.keyFeatures,
    required this.technologies,
    required this.contribution,
    required this.challenges,
    required this.lessonsLearned,
    required this.repositoryUrl,
    required this.demoUrl,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.publicationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String summary;
  final String problemStatement;
  final String description;
  final List<String> keyFeatures;
  final List<String> technologies;
  final String contribution;
  final String challenges;
  final String lessonsLearned;
  final String repositoryUrl;
  final String demoUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final ProjectStatus status;
  final ProjectPublicationStatus publicationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String? ?? '',
    problemStatement: json['problem_statement'] as String? ?? '',
    description: json['description'] as String? ?? '',
    keyFeatures: _readList(json['key_features']),
    technologies: _readList(json['technologies']),
    contribution: json['contribution'] as String? ?? '',
    challenges: json['challenges'] as String? ?? '',
    lessonsLearned: json['lessons_learned'] as String? ?? '',
    repositoryUrl: json['repository_url'] as String? ?? '',
    demoUrl: json['demo_url'] as String? ?? '',
    startDate: _readDate(json['start_date']),
    endDate: _readDate(json['end_date']),
    status: projectStatusFromDatabase(json['status'] as String?),
    publicationStatus: json['publication_status'] == 'published'
        ? ProjectPublicationStatus.published
        : ProjectPublicationStatus.draft,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

List<String> _cleanList(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

List<String> _readList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];

String? _dateOnly(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? _readDate(dynamic value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;
