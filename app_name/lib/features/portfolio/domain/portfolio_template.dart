import 'portfolio_content.dart';

enum PortfolioTemplate {
  light,
  dark;

  String get label => switch (this) {
    PortfolioTemplate.light => 'Light',
    PortfolioTemplate.dark => 'Dark',
  };
}

class PortfolioSelection {
  const PortfolioSelection({
    this.includeDisplayName = false,
    this.includeHeadline = false,
    this.includeOccupationTitle = false,
    this.includeBio = false,
    this.includePhoto = false,
    this.includeEmail = false,
    this.includePhone = false,
    this.includeGithub = false,
    this.includeLinkedIn = false,
    this.includeUpwork = false,
    this.includeJobstreet = false,
    this.includeWhatsApp = false,
    this.includeAdditionalLinks = false,
    this.projectIds = const {},
    this.skillIds = const {},
    this.educationIds = const {},
    this.experienceIds = const {},
    this.certificationIds = const {},
    this.achievementIds = const {},
  });

  factory PortfolioSelection.allFrom(PortfolioContent content) {
    final profile = content.profile.value;
    return PortfolioSelection(
      includeDisplayName: _hasText(profile?.displayName),
      includeHeadline: _hasText(profile?.headline),
      includeOccupationTitle: _hasText(profile?.occupationTitle),
      includeBio: _hasText(profile?.bio),
      includePhoto:
          _hasText(profile?.photoPath) && content.photoBytes.value != null,
      includeEmail: _hasText(profile?.contactEmail),
      includePhone: _hasText(profile?.phone),
      includeGithub: _hasText(profile?.githubUrl),
      includeLinkedIn: _hasText(profile?.linkedInUrl),
      includeUpwork: _hasText(profile?.upworkUrl),
      includeJobstreet: _hasText(profile?.jobstreetUrl),
      includeWhatsApp: _hasText(profile?.whatsAppNumber),
      includeAdditionalLinks:
          profile?.additionalLinks.any(
            (link) => _hasText(link.label) && _hasText(link.url),
          ) ??
          false,
      projectIds:
          content.projects.value?.map((project) => project.id).toSet() ??
          const {},
      skillIds:
          content.skills.value?.map((skill) => skill.id).toSet() ?? const {},
      educationIds:
          content.education.value?.map((record) => record.id).toSet() ??
          const {},
      experienceIds:
          content.experience.value?.map((record) => record.id).toSet() ??
          const {},
      certificationIds:
          content.certifications.value?.map((record) => record.id).toSet() ??
          const {},
      achievementIds:
          content.achievements.value?.map((record) => record.id).toSet() ??
          const {},
    );
  }

  final bool includeDisplayName;
  final bool includeHeadline;
  final bool includeOccupationTitle;
  final bool includeBio;
  final bool includePhoto;
  final bool includeEmail;
  final bool includePhone;
  final bool includeGithub;
  final bool includeLinkedIn;
  final bool includeUpwork;
  final bool includeJobstreet;
  final bool includeWhatsApp;
  final bool includeAdditionalLinks;
  final Set<String> projectIds;
  final Set<String> skillIds;
  final Set<String> educationIds;
  final Set<String> experienceIds;
  final Set<String> certificationIds;
  final Set<String> achievementIds;

  Map<String, dynamic> toJson() => {
    'includeDisplayName': includeDisplayName,
    'includeHeadline': includeHeadline,
    'includeOccupationTitle': includeOccupationTitle,
    'includeBio': includeBio,
    'includePhoto': includePhoto,
    'includeEmail': includeEmail,
    'includePhone': includePhone,
    'includeGithub': includeGithub,
    'includeLinkedIn': includeLinkedIn,
    'includeUpwork': includeUpwork,
    'includeJobstreet': includeJobstreet,
    'includeWhatsApp': includeWhatsApp,
    'includeAdditionalLinks': includeAdditionalLinks,
    'projectIds': _sortedIds(projectIds),
    'skillIds': _sortedIds(skillIds),
    'educationIds': _sortedIds(educationIds),
    'experienceIds': _sortedIds(experienceIds),
    'certificationIds': _sortedIds(certificationIds),
    'achievementIds': _sortedIds(achievementIds),
  };

  factory PortfolioSelection.fromJson(Map<String, dynamic> json) =>
      PortfolioSelection(
        includeDisplayName: json['includeDisplayName'] == true,
        includeHeadline: json['includeHeadline'] == true,
        includeOccupationTitle: json['includeOccupationTitle'] == true,
        includeBio: json['includeBio'] == true,
        includePhoto: json['includePhoto'] == true,
        includeEmail: json['includeEmail'] == true,
        includePhone: json['includePhone'] == true,
        includeGithub: json['includeGithub'] == true,
        includeLinkedIn: json['includeLinkedIn'] == true,
        includeUpwork: json['includeUpwork'] == true,
        includeJobstreet: json['includeJobstreet'] == true,
        includeWhatsApp: json['includeWhatsApp'] == true,
        includeAdditionalLinks: json['includeAdditionalLinks'] == true,
        projectIds: _readIds(json['projectIds']),
        skillIds: _readIds(json['skillIds']),
        educationIds: _readIds(json['educationIds']),
        experienceIds: _readIds(json['experienceIds']),
        certificationIds: _readIds(json['certificationIds']),
        achievementIds: _readIds(json['achievementIds']),
      );

  PortfolioSelection copyWith({
    bool? includeDisplayName,
    bool? includeHeadline,
    bool? includeOccupationTitle,
    bool? includeBio,
    bool? includePhoto,
    bool? includeEmail,
    bool? includePhone,
    bool? includeGithub,
    bool? includeLinkedIn,
    bool? includeUpwork,
    bool? includeJobstreet,
    bool? includeWhatsApp,
    bool? includeAdditionalLinks,
    Set<String>? projectIds,
    Set<String>? skillIds,
    Set<String>? educationIds,
    Set<String>? experienceIds,
    Set<String>? certificationIds,
    Set<String>? achievementIds,
  }) => PortfolioSelection(
    includeDisplayName: includeDisplayName ?? this.includeDisplayName,
    includeHeadline: includeHeadline ?? this.includeHeadline,
    includeOccupationTitle:
        includeOccupationTitle ?? this.includeOccupationTitle,
    includeBio: includeBio ?? this.includeBio,
    includePhoto: includePhoto ?? this.includePhoto,
    includeEmail: includeEmail ?? this.includeEmail,
    includePhone: includePhone ?? this.includePhone,
    includeGithub: includeGithub ?? this.includeGithub,
    includeLinkedIn: includeLinkedIn ?? this.includeLinkedIn,
    includeUpwork: includeUpwork ?? this.includeUpwork,
    includeJobstreet: includeJobstreet ?? this.includeJobstreet,
    includeWhatsApp: includeWhatsApp ?? this.includeWhatsApp,
    includeAdditionalLinks:
        includeAdditionalLinks ?? this.includeAdditionalLinks,
    projectIds: projectIds ?? this.projectIds,
    skillIds: skillIds ?? this.skillIds,
    educationIds: educationIds ?? this.educationIds,
    experienceIds: experienceIds ?? this.experienceIds,
    certificationIds: certificationIds ?? this.certificationIds,
    achievementIds: achievementIds ?? this.achievementIds,
  );
}

bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;

List<String> _sortedIds(Set<String> ids) => ids.toList()..sort();

Set<String> _readIds(Object? value) =>
    value is List ? value.whereType<String>().toSet() : const {};
