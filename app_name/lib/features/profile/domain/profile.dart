enum OccupationCategory {
  agriculture(
    'agriculture_forestry_fisheries',
    'Agriculture, forestry, and fisheries',
  ),
  arts('arts_media_design', 'Arts, media, and design'),
  business(
    'business_finance_administration',
    'Business, finance, and administration',
  ),
  construction(
    'construction_skilled_trades',
    'Construction and skilled trades',
  ),
  education('education_training', 'Education and training'),
  engineering('engineering_manufacturing', 'Engineering and manufacturing'),
  healthcare('healthcare_care_services', 'Healthcare and care services'),
  hospitality('hospitality_tourism', 'Hospitality and tourism'),
  technology('technology_digital', 'Information technology and digital work'),
  publicService('legal_public_service', 'Legal and public service'),
  science('science_research', 'Science and research'),
  sales('sales_customer_service', 'Sales and customer service'),
  transport('transportation_logistics', 'Transportation and logistics'),
  virtualAssistance(
    'virtual_assistance_remote_operations',
    'Virtual assistance and remote operations',
  ),
  community('community_nonprofit', 'Community and nonprofit work'),
  student('student_early_career', 'Student or early career'),
  other('other', 'Other');

  const OccupationCategory(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static OccupationCategory? fromDatabase(String? value) {
    for (final category in values) {
      if (category.databaseValue == value) return category;
    }
    return null;
  }
}

enum CareerStage {
  student('student', 'Studying'),
  earlyCareer('early_career', 'Starting my career'),
  experienced('experienced', 'Experienced professional'),
  careerChanger('career_changer', 'Changing careers'),
  returningToWork('returning_to_work', 'Returning to work'),
  selfEmployed('self_employed', 'Self-employed or freelance'),
  other('other', 'Another path');

  const CareerStage(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static CareerStage? fromDatabase(String? value) {
    for (final stage in values) {
      if (stage.databaseValue == value) return stage;
    }
    return null;
  }
}

enum EducationLevel {
  secondary('secondary', 'Secondary school'),
  vocational('vocational', 'Vocational training'),
  certificate('certificate', 'Certificate'),
  diploma('diploma', 'Diploma'),
  associate('associate', 'Associate degree'),
  bachelor('bachelor', 'Bachelor’s degree'),
  master('master', 'Master’s degree'),
  doctoral('doctoral', 'Doctoral degree'),
  other('other', 'Other or not listed');

  const EducationLevel(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static EducationLevel? fromDatabase(String? value) {
    for (final level in values) {
      if (level.databaseValue == value) return level;
    }
    return null;
  }
}

enum EducationStatus {
  inProgress('in_progress', 'In progress'),
  completed('completed', 'Completed'),
  paused('paused', 'Paused');

  const EducationStatus(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static EducationStatus fromDatabase(String? value) =>
      EducationStatus.values.firstWhere(
        (status) => status.databaseValue == value,
        orElse: () => EducationStatus.inProgress,
      );
}

enum ExperienceType {
  employment('employment', 'Employment'),
  freelance('freelance', 'Freelance or self-employed'),
  internship('internship', 'Internship'),
  volunteering('volunteering', 'Volunteering'),
  communityWork('community_work', 'Community work'),
  caregiving('caregiving', 'Caregiving'),
  independentPractice('independent_practice', 'Independent practice'),
  other('other', 'Other experience');

  const ExperienceType(this.databaseValue, this.label);
  final String databaseValue;
  final String label;

  static ExperienceType fromDatabase(String? value) =>
      ExperienceType.values.firstWhere(
        (type) => type.databaseValue == value,
        orElse: () => ExperienceType.other,
      );
}

class ProfileBackground {
  const ProfileBackground({
    required this.displayName,
    required this.username,
    this.headline = '',
    this.bio = '',
    this.occupationCategory,
    this.occupationTitle = '',
    this.careerStage,
    this.interests = const [],
    this.targetRoles = const [],
    this.photoPath,
    this.contactEmail,
    this.phone,
    this.githubUrl,
    this.linkedInUrl,
    this.jobstreetUrl,
    this.whatsAppNumber,
    this.additionalLinks = const [],
  });

  final String displayName;
  final String username;
  final String headline;
  final String bio;
  final OccupationCategory? occupationCategory;
  final String occupationTitle;
  final CareerStage? careerStage;
  final List<String> interests;
  final List<String> targetRoles;
  final String? photoPath;
  final String? contactEmail;
  final String? phone;
  final String? githubUrl;
  final String? linkedInUrl;
  final String? jobstreetUrl;
  final String? whatsAppNumber;
  final List<ProfileContactLink> additionalLinks;

  Map<String, dynamic> toDatabaseFields() => {
    'display_name': displayName.trim(),
    'username': username.trim().toLowerCase(),
    'headline': _nullableText(headline),
    'bio': bio.trim(),
    'occupation_category': occupationCategory?.databaseValue,
    'occupation_title': _nullableText(occupationTitle),
    'career_stage': careerStage?.databaseValue,
    'interests': _cleanList(interests),
    'target_roles': _cleanList(targetRoles),
    'photo_path': _nullableText(photoPath ?? ''),
    'contact_email': _nullableText(contactEmail ?? ''),
    'phone': _nullableText(phone ?? ''),
    'github_url': _nullableText(githubUrl ?? ''),
    'linkedin_url': _nullableText(linkedInUrl ?? ''),
    'jobstreet_url': _nullableText(jobstreetUrl ?? ''),
    'whatsapp_number': _nullableText(whatsAppNumber ?? ''),
    'additional_links': additionalLinks
        .map((link) => link.toDatabaseFields())
        .toList(growable: false),
  };

  factory ProfileBackground.fromJson(Map<String, dynamic> json) =>
      ProfileBackground(
        displayName: json['display_name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        bio: json['bio'] as String? ?? '',
        occupationCategory: OccupationCategory.fromDatabase(
          json['occupation_category'] as String?,
        ),
        occupationTitle: json['occupation_title'] as String? ?? '',
        careerStage: CareerStage.fromDatabase(json['career_stage'] as String?),
        interests: _readList(json['interests']),
        targetRoles: _readList(json['target_roles']),
        photoPath: json['photo_path'] as String?,
        contactEmail: json['contact_email'] as String?,
        phone: json['phone'] as String?,
        githubUrl: json['github_url'] as String?,
        linkedInUrl: json['linkedin_url'] as String?,
        jobstreetUrl: json['jobstreet_url'] as String?,
        whatsAppNumber: json['whatsapp_number'] as String?,
        additionalLinks: _readProfileContactLinks(json['additional_links']),
      );
}

class ProfileContactLink {
  const ProfileContactLink({required this.label, required this.url});

  final String label;
  final String url;

  Map<String, String> toDatabaseFields() => {
    'label': label.trim(),
    'url': url.trim(),
  };

  factory ProfileContactLink.fromJson(Map<String, dynamic> json) =>
      ProfileContactLink(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

class EducationDraft {
  const EducationDraft({
    required this.title,
    this.institution = '',
    this.level,
    this.status = EducationStatus.inProgress,
    this.startDate,
    this.endDate,
    this.description = '',
  });

  final String title;
  final String institution;
  final EducationLevel? level;
  final EducationStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;

  Map<String, dynamic> toDatabaseFields() => {
    'title': title.trim(),
    'institution': _nullableText(institution),
    'level': level?.databaseValue,
    'status': status.databaseValue,
    'start_date': _dateOnly(startDate),
    'end_date': _dateOnly(endDate),
    'description': description.trim(),
  };
}

class EducationRecord extends EducationDraft {
  const EducationRecord({
    required this.id,
    required this.userId,
    required super.title,
    super.institution,
    super.level,
    super.status,
    super.startDate,
    super.endDate,
    super.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EducationRecord.fromJson(Map<String, dynamic> json) =>
      EducationRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String? ?? '',
        institution: json['institution'] as String? ?? '',
        level: EducationLevel.fromDatabase(json['level'] as String?),
        status: EducationStatus.fromDatabase(json['status'] as String?),
        startDate: _readDate(json['start_date']),
        endDate: _readDate(json['end_date']),
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class ExperienceDraft {
  const ExperienceDraft({
    required this.title,
    required this.type,
    this.organization,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description = '',
  });

  final String title;
  final String? organization;
  final ExperienceType type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;

  Map<String, dynamic> toDatabaseFields() => {
    'title': title.trim(),
    'organization': _nullableText(organization ?? ''),
    'experience_type': type.databaseValue,
    'start_date': _dateOnly(startDate),
    'end_date': isCurrent ? null : _dateOnly(endDate),
    'is_current': isCurrent,
    'description': description.trim(),
  };
}

class ExperienceRecord extends ExperienceDraft {
  const ExperienceRecord({
    required this.id,
    required this.userId,
    required super.title,
    required super.type,
    super.organization,
    super.startDate,
    super.endDate,
    super.isCurrent,
    super.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ExperienceRecord.fromJson(Map<String, dynamic> json) =>
      ExperienceRecord(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String? ?? '',
        organization: json['organization'] as String?,
        type: ExperienceType.fromDatabase(json['experience_type'] as String?),
        startDate: _readDate(json['start_date']),
        endDate: _readDate(json['end_date']),
        isCurrent: json['is_current'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

String? _nullableText(String value) =>
    value.trim().isEmpty ? null : value.trim();

List<String> _cleanList(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

List<String> _readList(dynamic value) => value is List
    ? value.map((item) => item.toString()).toList(growable: false)
    : const [];

List<ProfileContactLink> _readProfileContactLinks(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (item) => ProfileContactLink.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
      .toList(growable: false);
}

String? _dateOnly(DateTime? date) => date == null
    ? null
    : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? _readDate(dynamic value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;
