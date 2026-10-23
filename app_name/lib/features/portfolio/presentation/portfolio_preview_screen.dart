import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../data/portfolio_content_repository.dart';
import '../domain/portfolio_content.dart';
import '../domain/portfolio_record.dart';

class PortfolioPreviewScreen extends StatefulWidget {
  const PortfolioPreviewScreen({
    super.key,
    required this.repository,
    required this.userId,
    required this.onEditProfile,
    required this.onOpenProjects,
    required this.onOpenSkills,
    required this.onOpenRecord,
    required this.onOpenEvidence,
    this.onBuildSite,
    this.onBuildResume,
  });

  final PortfolioContentRepository? repository;
  final String? userId;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenSkills;
  final ValueChanged<PortfolioRecordType> onOpenRecord;
  final VoidCallback onOpenEvidence;
  final ValueChanged<PortfolioContent>? onBuildSite;
  final ValueChanged<PortfolioContent>? onBuildResume;

  @override
  State<PortfolioPreviewScreen> createState() => _PortfolioPreviewScreenState();
}

class _PortfolioPreviewScreenState extends State<PortfolioPreviewScreen> {
  late Future<PortfolioContent?> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = _loadContent();
  }

  Future<PortfolioContent?> _loadContent() {
    final repository = widget.repository;
    final userId = widget.userId;
    if (repository == null || userId == null || userId.isEmpty) {
      return Future.value();
    }
    return repository.loadPrivateContent(userId);
  }

  Future<void> _refresh() async {
    setState(() => _contentFuture = _loadContent());
    await _contentFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
              children: [
                Text(
                  'Your private portfolio',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Private preview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review how your saved work comes together. Nothing here is public unless you choose to publish it later.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                _PrivateNotice(),
                const SizedBox(height: 20),
                FutureBuilder<PortfolioContent?>(
                  future: _contentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return _LoadFailure(
                        onRetry: _refresh,
                        message: 'Your private portfolio could not be loaded.',
                      );
                    }
                    final content = snapshot.data;
                    if (content == null) {
                      return _NotConnected(onEditProfile: widget.onEditProfile);
                    }
                    return _PortfolioContentView(
                      content: content,
                      onEditProfile: widget.onEditProfile,
                      onOpenProjects: widget.onOpenProjects,
                      onOpenSkills: widget.onOpenSkills,
                      onOpenRecord: widget.onOpenRecord,
                      onOpenEvidence: widget.onOpenEvidence,
                      onBuildSite: widget.onBuildSite,
                      onBuildResume: widget.onBuildResume,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioContentView extends StatelessWidget {
  const _PortfolioContentView({
    required this.content,
    required this.onEditProfile,
    required this.onOpenProjects,
    required this.onOpenSkills,
    required this.onOpenRecord,
    required this.onOpenEvidence,
    this.onBuildSite,
    this.onBuildResume,
  });

  final PortfolioContent content;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenSkills;
  final ValueChanged<PortfolioRecordType> onOpenRecord;
  final VoidCallback onOpenEvidence;
  final ValueChanged<PortfolioContent>? onBuildSite;
  final ValueChanged<PortfolioContent>? onBuildResume;

  @override
  Widget build(BuildContext context) {
    final suggestions = PortfolioReadiness.evaluate(content);
    final covered = suggestions
        .where((suggestion) => suggestion.isCovered)
        .length;
    final profile = content.profile.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadinessCard(
          suggestions: suggestions,
          covered: covered,
          onOpen: _openDestination,
        ),
        if (onBuildSite case final onBuildSite?) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onBuildSite(content),
            icon: const Icon(Icons.web_outlined),
            label: const Text('Build your website'),
          ),
        ],
        if (onBuildResume case final onBuildResume?) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => onBuildResume(content),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Preview your resume'),
          ),
        ],
        const SizedBox(height: 24),
        if (profile != null &&
            [
              profile.displayName,
              profile.headline,
              profile.occupationTitle,
              profile.bio,
            ].any((value) => value.trim().isNotEmpty)) ...[
          _SectionHeading(
            icon: Icons.person_outline,
            title: 'Profile',
            color: AppColors.indigo,
            onAction: onEditProfile,
            actionLabel: 'Edit profile',
          ),
          const SizedBox(height: 10),
          _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.photoUrl.value case final photoUrl?)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(photoUrl),
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (profile.displayName.trim().isNotEmpty)
                            Text(
                              profile.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          if (profile.headline.trim().isNotEmpty)
                            Text(profile.headline),
                          if (profile.occupationTitle.trim().isNotEmpty)
                            Text(profile.occupationTitle),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!content.photoUrl.isAvailable) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Profile photo could not be loaded. Pull to refresh.',
                  ),
                ],
                if (profile.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio),
                ],
                for (final contact in [
                  ('Email', profile.contactEmail),
                  ('Phone', profile.phone),
                  ('GitHub', profile.githubUrl),
                  ('LinkedIn', profile.linkedInUrl),
                  ('Upwork', profile.upworkUrl),
                  ('JobStreet', profile.jobstreetUrl),
                  ('WhatsApp', profile.whatsAppNumber),
                ])
                  if (contact.$2.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${contact.$1}: ${contact.$2}'),
                    ),
                for (final link in profile.additionalLinks)
                  if (link.label.trim().isNotEmpty &&
                      link.url.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('${link.label}: ${link.url}'),
                    ),
              ],
            ),
          ),
        ],
        _buildProjectSection(),
        _buildSkillsSection(),
        _buildExperienceSection(),
        _buildEducationSection(),
        _buildRecordSection(
          context,
          title: 'Certifications',
          icon: Icons.workspace_premium_outlined,
          records: content.certifications,
          onAction: () => onOpenRecord(PortfolioRecordType.certification),
          actionLabel: 'Manage credentials',
          isAvailable: content.certifications.isAvailable,
        ),
        _buildRecordSection(
          context,
          title: 'Achievements',
          icon: Icons.emoji_events_outlined,
          records: content.achievements,
          onAction: () => onOpenRecord(PortfolioRecordType.achievement),
          actionLabel: 'Manage achievements',
          isAvailable: content.achievements.isAvailable,
        ),
        _buildEvidenceSection(),
      ],
    );
  }

  Widget _buildProjectSection() {
    final projects = content.projects.value;
    return _section(
      title: 'Projects',
      icon: Icons.folder_outlined,
      color: AppColors.deepNavy,
      isAvailable: content.projects.isAvailable,
      onAction: onOpenProjects,
      actionLabel: 'View projects',
      children: [
        for (final project in projects ?? [])
          _PreviewRecord(
            title: project.title,
            subtitle: project.summary,
            detail: [
              project.description,
              project.statusLabel,
              if (project.technologies.isNotEmpty)
                project.technologies.join(', '),
            ].where((item) => item.trim().isNotEmpty).join('\n'),
            secondaryDetail: project.contribution.trim().isEmpty
                ? ''
                : 'Contribution: ${project.contribution}',
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skills = content.skills.value;
    return _section(
      title: 'Skills',
      icon: Icons.lightbulb_outline,
      color: AppColors.teal,
      isAvailable: content.skills.isAvailable,
      onAction: onOpenSkills,
      actionLabel: 'View skills',
      children: [
        for (final skill in skills ?? [])
          _PreviewRecord(
            title: skill.name,
            subtitle: skill.category,
            detail: [
              skill.status,
              if (skill.projectTitles.isNotEmpty)
                'Linked to ${skill.projectTitles.join(', ')}',
            ].join(' · '),
          ),
      ],
    );
  }

  Widget _buildExperienceSection() => _section(
    title: 'Experience',
    icon: Icons.work_outline,
    color: AppColors.amber,
    isAvailable: content.experience.isAvailable,
    onAction: onEditProfile,
    actionLabel: 'Edit profile',
    children: [
      for (final experience in content.experience.value ?? [])
        _PreviewRecord(
          title: experience.title,
          subtitle: [
            experience.type,
            if (experience.organization.isNotEmpty) experience.organization,
            if (experience.isCurrent) 'Current',
          ].join(' · '),
          detail: experience.description,
        ),
    ],
  );

  Widget _buildEducationSection() => _section(
    title: 'Education and training',
    icon: Icons.school_outlined,
    color: AppColors.teal,
    isAvailable: content.education.isAvailable,
    onAction: onEditProfile,
    actionLabel: 'Edit profile',
    children: [
      for (final education in content.education.value ?? [])
        _PreviewRecord(
          title: education.title,
          subtitle: [
            education.institution,
            education.level,
            education.status,
          ].where((item) => item.trim().isNotEmpty).join(' · '),
          detail: education.description,
        ),
    ],
  );

  Widget _buildRecordSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required PortfolioSource<List<PortfolioRecordContent>> records,
    required bool isAvailable,
    required VoidCallback onAction,
    required String actionLabel,
  }) => _section(
    title: title,
    icon: icon,
    color: AppColors.amber,
    isAvailable: isAvailable,
    onAction: onAction,
    actionLabel: actionLabel,
    children: [
      for (final record in records.value ?? [])
        _PreviewRecord(
          title: record.title,
          subtitle: record.source,
          detail: record.description,
        ),
    ],
  );

  Widget _buildEvidenceSection() => _section(
    title: 'Private evidence',
    icon: Icons.attach_file_outlined,
    color: AppColors.teal,
    isAvailable: content.evidence.isAvailable,
    onAction: onOpenEvidence,
    actionLabel: 'Open evidence library',
    children: [
      for (final evidence in content.evidence.value ?? [])
        _PreviewRecord(
          title: evidence.title,
          subtitle: evidence.kind,
          detail: [
            evidence.description,
            if (evidence.targetTitles.isNotEmpty)
              'Supports ${evidence.targetTitles.join(', ')}',
          ].where((item) => item.isNotEmpty).join(' · '),
        ),
    ],
  );

  Widget _section({
    required String title,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onAction,
    required String actionLabel,
    required List<Widget> children,
  }) {
    if (isAvailable && children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            icon: icon,
            title: title,
            color: color,
            onAction: onAction,
            actionLabel: actionLabel,
          ),
          const SizedBox(height: 10),
          if (!isAvailable)
            const _Surface(
              child: Text('This section could not be loaded. Pull to refresh.'),
            )
          else
            _Surface(child: Column(children: children)),
        ],
      ),
    );
  }

  void _openDestination(PortfolioReadinessDestination destination) {
    switch (destination) {
      case PortfolioReadinessDestination.profile ||
          PortfolioReadinessDestination.contact:
        onEditProfile();
      case PortfolioReadinessDestination.projects:
        onOpenProjects();
      case PortfolioReadinessDestination.skills:
        onOpenSkills();
      case PortfolioReadinessDestination.evidence:
        onOpenEvidence();
    }
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({
    required this.suggestions,
    required this.covered,
    required this.onOpen,
  });

  final List<ReadinessSuggestion> suggestions;
  final int covered;
  final ValueChanged<PortfolioReadinessDestination> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Content coverage', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'A practical checklist of what you have recorded in Prooffolio, not a rating of your career.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: suggestions.isEmpty ? 0 : covered / suggestions.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.indigo,
                  backgroundColor: AppColors.indigoContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text('$covered of ${suggestions.length} areas'),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Coverage measures saved content only.'),
          const SizedBox(height: 12),
          for (final suggestion in suggestions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                suggestion.isCovered
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: suggestion.isCovered
                    ? AppColors.teal
                    : AppColors.slateGray,
              ),
              title: Text(suggestion.label),
              subtitle: Text(suggestion.explanation),
              trailing: IconButton(
                tooltip: 'Open ${suggestion.label.toLowerCase()}',
                onPressed: () => onOpen(suggestion.destination),
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.color,
    required this.onAction,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppIconTile(
        icon: icon,
        size: 38,
        iconSize: 19,
        color: color,
        backgroundColor: color.withValues(alpha: .12),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onAction, child: Text(actionLabel)),
    ],
  );
}

class _PreviewRecord extends StatelessWidget {
  const _PreviewRecord({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.secondaryDetail = '',
  });

  final String title;
  final String subtitle;
  final String detail;
  final String secondaryDetail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Align(alignment: Alignment.centerLeft, child: Text(subtitle)),
        ],
        if (detail.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Align(alignment: Alignment.centerLeft, child: Text(detail)),
        ],
        if (secondaryDetail.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Align(alignment: Alignment.centerLeft, child: Text(secondaryDetail)),
        ],
        const Divider(height: 18),
      ],
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.lightSlate),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    ),
    child: child,
  );
}

class _PrivateNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.indigoContainer,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock_outline, color: AppColors.indigo),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'This preview is private to your account. Evidence files and links are not published here.',
          ),
        ),
      ],
    ),
  );
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.onEditProfile});

  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your saved profile and work will appear here.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Add a short introduction, work experience, education, projects, skills, or evidence. Projects are optional.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onEditProfile,
          icon: const Icon(Icons.person_outline),
          label: const Text('Edit profile'),
        ),
      ],
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Check your connection and try again.'),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
