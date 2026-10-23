import 'dart:typed_data';

import 'portfolio_content.dart';

class ResumeContent {
  const ResumeContent({
    required this.displayName,
    required this.headline,
    required this.summary,
    required this.contactDetails,
    required this.sections,
    required this.unavailableSections,
    required this.photoBytes,
  });

  factory ResumeContent.fromPortfolioContent(PortfolioContent content) {
    final profile = content.profile.value;
    final unavailable = <String>[
      if (!content.profile.isAvailable) 'Profile',
      if (!content.experience.isAvailable) 'Experience',
      if (!content.education.isAvailable) 'Education',
      if (!content.skills.isAvailable) 'Skills',
      if (!content.projects.isAvailable) 'Projects',
      if (!content.certifications.isAvailable) 'Certifications',
      if (!content.achievements.isAvailable) 'Achievements',
    ];
    final sections = <ResumeSection>[
      _makeSection(
        'Experience',
        _newestFirst(
          content.experience.value ?? const [],
          (item) => item.startDate,
        ).map(
          (item) => ResumeEntry(
            title: item.title,
            subtitle: _firstNonEmpty([item.organization, item.type]),
            dateRange: _dateRange(
              item.startDate,
              item.isCurrent ? null : item.endDate,
              isCurrent: item.isCurrent,
            ),
            description: item.description,
          ),
        ),
      ),
      _makeSection(
        'Education',
        _newestFirst(
          content.education.value ?? const [],
          (item) => item.endDate ?? item.startDate,
        ).map(
          (item) => ResumeEntry(
            title: item.title,
            subtitle: _joinNonEmpty([item.institution, item.level]),
            dateRange: _dateRange(item.startDate, item.endDate),
            description: item.description,
          ),
        ),
      ),
      _makeSection(
        'Skills',
        (content.skills.value ?? const []).map(
          (item) => ResumeEntry(title: item.name, subtitle: item.category),
        ),
      ),
      _makeSection(
        'Projects',
        _newestFirst(
          content.projects.value ?? const [],
          (item) => item.startDate,
        ).map(
          (item) => ResumeEntry(
            title: item.title,
            subtitle: item.technologies.join(', '),
            dateRange: _dateRange(item.startDate, item.endDate),
            description: _joinNonEmpty([
              item.summary,
              item.description,
              if (item.contribution.trim().isNotEmpty)
                'Contribution: ${item.contribution}',
            ], separator: '\n'),
          ),
        ),
      ),
      _makeSection(
        'Certifications',
        _newestFirst(
          content.certifications.value ?? const [],
          (item) => item.achievedOn,
        ).map(
          (item) => ResumeEntry(
            title: item.title,
            subtitle: item.source,
            dateRange: _dateRange(item.achievedOn, null),
            description: item.description,
          ),
        ),
      ),
      _makeSection(
        'Achievements',
        _newestFirst(
          content.achievements.value ?? const [],
          (item) => item.achievedOn,
        ).map(
          (item) => ResumeEntry(
            title: item.title,
            subtitle: item.source,
            dateRange: _dateRange(item.achievedOn, null),
            description: item.description,
          ),
        ),
      ),
    ].where((section) => section.entries.isNotEmpty).toList();

    return ResumeContent(
      displayName: profile?.displayName.trim() ?? '',
      headline: profile?.headline.trim() ?? '',
      summary: profile?.bio.trim() ?? '',
      contactDetails: _contactDetails(profile),
      sections: sections,
      unavailableSections: unavailable,
      photoBytes: content.photoBytes.value,
    );
  }

  final String displayName;
  final String headline;
  final String summary;
  final List<ResumeContactDetail> contactDetails;
  final List<ResumeSection> sections;
  final List<String> unavailableSections;
  final Uint8List? photoBytes;
}

class ResumeContactDetail {
  const ResumeContactDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class ResumeSection {
  const ResumeSection({required this.heading, required this.entries});

  final String heading;
  final List<ResumeEntry> entries;
}

class ResumeEntry {
  const ResumeEntry({
    required this.title,
    this.subtitle = '',
    this.dateRange = '',
    this.description = '',
  });

  final String title;
  final String subtitle;
  final String dateRange;
  final String description;
}

List<ResumeContactDetail> _contactDetails(PortfolioProfile? profile) {
  if (profile == null) return const [];
  final details = <ResumeContactDetail>[];
  void add(String label, String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      details.add(ResumeContactDetail(label: label, value: trimmed));
    }
  }

  add('Email', profile.contactEmail);
  add('Phone', profile.phone);
  add('GitHub', profile.githubUrl);
  add('LinkedIn', profile.linkedInUrl);
  add('Upwork', profile.upworkUrl);
  add('JobStreet', profile.jobstreetUrl);
  add('WhatsApp', profile.whatsAppNumber);
  for (final link in profile.additionalLinks) {
    add(link.label, link.url);
  }
  return details;
}

ResumeSection _makeSection(String heading, Iterable<ResumeEntry> entries) =>
    ResumeSection(
      heading: heading,
      entries: entries.where((entry) => entry.title.trim().isNotEmpty).toList(),
    );

List<T> _newestFirst<T>(List<T> items, DateTime? Function(T) dateOf) {
  final sorted = List<T>.of(items);
  sorted.sort((a, b) {
    final aDate = dateOf(a);
    final bDate = dateOf(b);
    if (aDate == null) return bDate == null ? 0 : 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });
  return sorted;
}

String _dateRange(DateTime? start, DateTime? end, {bool isCurrent = false}) {
  final startLabel = _dateLabel(start);
  final endLabel = isCurrent ? 'Present' : _dateLabel(end);
  if (startLabel.isEmpty) return endLabel;
  if (endLabel.isEmpty) return startLabel;
  return '$startLabel - $endLabel';
}

String _dateLabel(DateTime? date) {
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _firstNonEmpty(List<String> values) =>
    values.firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');

String _joinNonEmpty(List<String> values, {String separator = ', '}) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .join(separator);
