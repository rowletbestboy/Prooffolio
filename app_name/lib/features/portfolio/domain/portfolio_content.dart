import 'dart:typed_data';

import '../../evidence/domain/evidence.dart';
import '../../profile/domain/profile.dart';
import '../../projects/domain/project.dart';
import '../../skills/domain/skill.dart';
import 'portfolio_record.dart';

class PortfolioSource<T> {
  const PortfolioSource.available(this.value) : error = null;

  const PortfolioSource.unavailable(this.error) : value = null;

  final T? value;
  final Object? error;

  bool get isAvailable => error == null;
}

class PortfolioContent {
  const PortfolioContent({
    required this.profile,
    required this.photoUrl,
    this.photoBytes = const PortfolioSource<Uint8List?>.available(null),
    required this.projects,
    required this.skills,
    required this.education,
    required this.experience,
    required this.certifications,
    required this.achievements,
    required this.evidence,
  });

  final PortfolioSource<PortfolioProfile?> profile;
  final PortfolioSource<String?> photoUrl;
  final PortfolioSource<Uint8List?> photoBytes;
  final PortfolioSource<List<PortfolioProject>> projects;
  final PortfolioSource<List<PortfolioSkill>> skills;
  final PortfolioSource<List<PortfolioEducation>> education;
  final PortfolioSource<List<PortfolioExperience>> experience;
  final PortfolioSource<List<PortfolioRecordContent>> certifications;
  final PortfolioSource<List<PortfolioRecordContent>> achievements;
  final PortfolioSource<List<PortfolioEvidence>> evidence;
}

class PortfolioProfile {
  const PortfolioProfile({
    required this.displayName,
    required this.username,
    required this.headline,
    required this.bio,
    required this.occupationTitle,
    required this.photoPath,
    required this.contactEmail,
    required this.phone,
    required this.githubUrl,
    required this.linkedInUrl,
    this.upworkUrl = '',
    required this.jobstreetUrl,
    required this.whatsAppNumber,
    required this.additionalLinks,
  });

  factory PortfolioProfile.fromProfileBackground(ProfileBackground profile) =>
      PortfolioProfile(
        displayName: profile.displayName,
        username: profile.username,
        headline: profile.headline,
        bio: profile.bio,
        occupationTitle: profile.occupationTitle,
        photoPath: profile.photoPath,
        contactEmail: profile.contactEmail ?? '',
        phone: profile.phone ?? '',
        githubUrl: profile.githubUrl ?? '',
        linkedInUrl: profile.linkedInUrl ?? '',
        upworkUrl: profile.upworkUrl ?? '',
        jobstreetUrl: profile.jobstreetUrl ?? '',
        whatsAppNumber: profile.whatsAppNumber ?? '',
        additionalLinks: profile.additionalLinks,
      );

  final String displayName;
  final String username;
  final String headline;
  final String bio;
  final String occupationTitle;
  final String? photoPath;
  final String contactEmail;
  final String phone;
  final String githubUrl;
  final String linkedInUrl;
  final String upworkUrl;
  final String jobstreetUrl;
  final String whatsAppNumber;
  final List<ProfileContactLink> additionalLinks;

  bool get hasContactOptions =>
      [
        contactEmail,
        phone,
        githubUrl,
        linkedInUrl,
        upworkUrl,
        jobstreetUrl,
        whatsAppNumber,
      ].any((value) => value.trim().isNotEmpty) ||
      additionalLinks.any(
        (link) => link.label.trim().isNotEmpty && link.url.trim().isNotEmpty,
      );
}

class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.contribution,
    required this.technologies,
    this.repositoryUrl = '',
    this.demoUrl = '',
    required this.statusLabel,
    required this.startDate,
    required this.endDate,
  });

  factory PortfolioProject.fromProject(Project project) => PortfolioProject(
    id: project.id,
    title: project.title,
    summary: project.summary,
    description: project.description,
    contribution: project.contribution,
    technologies: project.technologies,
    repositoryUrl: project.repositoryUrl,
    demoUrl: project.demoUrl,
    statusLabel: switch (project.status) {
      ProjectStatus.inProgress => 'In progress',
      ProjectStatus.completed => 'Completed',
      ProjectStatus.paused => 'Paused',
    },
    startDate: project.startDate,
    endDate: project.endDate,
  );

  final String id;
  final String title;
  final String summary;
  final String description;
  final String contribution;
  final List<String> technologies;
  final String repositoryUrl;
  final String demoUrl;
  final String statusLabel;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasDetails =>
      summary.trim().isNotEmpty ||
      description.trim().isNotEmpty ||
      contribution.trim().isNotEmpty;
}

class PortfolioSkill {
  const PortfolioSkill({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.projectTitles,
  });

  factory PortfolioSkill.fromSkill(Skill skill) => PortfolioSkill(
    id: skill.id,
    name: skill.name,
    category: skill.category.label,
    status: skill.status.label,
    projectTitles: skill.projectTitles,
  );

  final String id;
  final String name;
  final String category;
  final String status;
  final List<String> projectTitles;
}

class PortfolioEducation {
  const PortfolioEducation({
    required this.id,
    required this.title,
    required this.institution,
    required this.level,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory PortfolioEducation.fromRecord(EducationRecord record) =>
      PortfolioEducation(
        id: record.id,
        title: record.title,
        institution: record.institution,
        level: record.level?.label ?? '',
        status: record.status.label,
        startDate: record.startDate,
        endDate: record.endDate,
        description: record.description,
      );

  final String id;
  final String title;
  final String institution;
  final String level;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
}

class PortfolioExperience {
  const PortfolioExperience({
    required this.id,
    required this.title,
    required this.organization,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
  });

  factory PortfolioExperience.fromRecord(ExperienceRecord record) =>
      PortfolioExperience(
        id: record.id,
        title: record.title,
        organization: record.organization ?? '',
        type: record.type.label,
        startDate: record.startDate,
        endDate: record.endDate,
        isCurrent: record.isCurrent,
        description: record.description,
      );

  final String id;
  final String title;
  final String organization;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;
}

class PortfolioRecordContent {
  const PortfolioRecordContent({
    required this.id,
    required this.title,
    required this.source,
    required this.description,
    required this.achievedOn,
    required this.expiresOn,
  });

  factory PortfolioRecordContent.fromRecord(PortfolioRecord record) =>
      PortfolioRecordContent(
        id: record.id,
        title: record.title,
        source: record.source,
        description: record.description,
        achievedOn: record.achievedOn,
        expiresOn: record.expiresOn,
      );

  final String id;
  final String title;
  final String source;
  final String description;
  final DateTime? achievedOn;
  final DateTime? expiresOn;
}

class PortfolioEvidence {
  const PortfolioEvidence({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.targetTitles,
  });

  factory PortfolioEvidence.fromEvidence(EvidenceRecord record) =>
      PortfolioEvidence(
        id: record.id,
        title: record.title,
        description: record.description,
        kind: record.kind.label,
        targetTitles: record.targets.map((target) => target.title).toList(),
      );

  final String id;
  final String title;
  final String description;
  final String kind;
  final List<String> targetTitles;
}

enum PortfolioReadinessDestination {
  profile,
  projects,
  skills,
  evidence,
  contact,
}

class ReadinessSuggestion {
  const ReadinessSuggestion({
    required this.label,
    required this.explanation,
    required this.isCovered,
    required this.destination,
  });

  final String label;
  final String explanation;
  final bool isCovered;
  final PortfolioReadinessDestination destination;
}

abstract final class PortfolioReadiness {
  static List<ReadinessSuggestion> evaluate(PortfolioContent content) => [
    _suggestion(
      label: 'Profile basics',
      destination: PortfolioReadinessDestination.profile,
      isAvailable: content.profile.isAvailable,
      isCovered: _hasProfileBasics(content.profile.value),
      coveredExplanation: 'Your name and introduction are represented.',
      missingExplanation:
          'Add a short headline, role, or introduction to describe your background.',
    ),
    _suggestion(
      label: 'Project detail',
      destination: PortfolioReadinessDestination.projects,
      isAvailable: content.projects.isAvailable,
      isCovered:
          content.projects.value?.any(
            (project) => project.title.trim().isNotEmpty && project.hasDetails,
          ) ??
          false,
      coveredExplanation:
          'At least one project includes a description of the work.',
      missingExplanation:
          'Add a summary or contribution to a project so visitors can understand the work.',
    ),
    _suggestion(
      label: 'Skills',
      destination: PortfolioReadinessDestination.skills,
      isAvailable: content.skills.isAvailable,
      isCovered: content.skills.value?.isNotEmpty ?? false,
      coveredExplanation: 'You have recorded skills in your private library.',
      missingExplanation:
          'Add skills you want to include in your portfolio. Skill claims remain self-reported.',
    ),
    _suggestion(
      label: 'Supporting evidence',
      destination: PortfolioReadinessDestination.evidence,
      isAvailable: content.evidence.isAvailable,
      isCovered: content.evidence.value?.isNotEmpty ?? false,
      coveredExplanation:
          'You have private evidence records to support your work.',
      missingExplanation:
          'Add a private file or link that supports a project, skill, or experience.',
    ),
    _suggestion(
      label: 'Contact options',
      destination: PortfolioReadinessDestination.contact,
      isAvailable: content.profile.isAvailable,
      isCovered: content.profile.value?.hasContactOptions ?? false,
      coveredExplanation:
          'At least one optional contact channel is available in your profile.',
      missingExplanation:
          'Add an optional contact channel if you want visitors to be able to reach you.',
    ),
  ];

  static bool _hasProfileBasics(PortfolioProfile? profile) =>
      profile != null &&
      profile.displayName.trim().isNotEmpty &&
      [
        profile.headline,
        profile.occupationTitle,
        profile.bio,
      ].any((value) => value.trim().isNotEmpty);

  static ReadinessSuggestion _suggestion({
    required String label,
    required PortfolioReadinessDestination destination,
    required bool isAvailable,
    required bool isCovered,
    required String coveredExplanation,
    required String missingExplanation,
  }) {
    if (!isAvailable) {
      return ReadinessSuggestion(
        label: label,
        explanation: 'This information could not be loaded. Refresh to retry.',
        isCovered: false,
        destination: destination,
      );
    }
    return ReadinessSuggestion(
      label: label,
      explanation: isCovered ? coveredExplanation : missingExplanation,
      isCovered: isCovered,
      destination: destination,
    );
  }
}
