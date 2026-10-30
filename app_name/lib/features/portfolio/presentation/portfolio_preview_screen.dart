import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.onBack,
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
  final VoidCallback? onBack;
  final ValueChanged<PortfolioContent>? onBuildSite;
  final ValueChanged<PortfolioContent>? onBuildResume;

  @override
  State<PortfolioPreviewScreen> createState() => _PortfolioPreviewScreenState();
}

class _PortfolioPreviewScreenState extends State<PortfolioPreviewScreen> {
  late Future<PortfolioContent?> _contentFuture;
  final Map<_PortfolioSection, GlobalKey> _sectionKeys = {
    for (final section in _PortfolioSection.values) section: GlobalKey(),
  };
  _PortfolioSection _selectedSection = _PortfolioSection.about;

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

  Future<void> _selectSection(_PortfolioSection section) async {
    setState(() => _selectedSection = section);
    final targetContext = _sectionKeys[section]?.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsets.fromLTRB(
                gutter,
                16,
                gutter,
                AppTheme.floatingNavigationContentInset +
                    MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                _PortfolioPageHeader(
                  onBack:
                      widget.onBack ??
                      () {
                        Navigator.of(context).maybePop();
                      },
                  onEditProfile: widget.onEditProfile,
                  onOpenProjects: widget.onOpenProjects,
                  onOpenSkills: widget.onOpenSkills,
                  onOpenEvidence: widget.onOpenEvidence,
                ),
                const SizedBox(height: 18),
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
                      sectionKeys: _sectionKeys,
                      selectedSection: _selectedSection,
                      onSelectSection: _selectSection,
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

enum _PortfolioSection {
  about('About'),
  projects('Projects'),
  skills('Skills'),
  contact('Contact');

  const _PortfolioSection(this.label);

  final String label;
}

class _PortfolioLink {
  const _PortfolioLink({
    required this.label,
    required this.url,
    required this.icon,
  });

  final String label;
  final String url;
  final IconData icon;
}

enum _PortfolioHeaderAction { editProfile, projects, skills, evidence }

class _PortfolioPageHeader extends StatelessWidget {
  const _PortfolioPageHeader({
    required this.onBack,
    required this.onEditProfile,
    required this.onOpenProjects,
    required this.onOpenSkills,
    required this.onOpenEvidence,
  });

  final VoidCallback onBack;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenSkills;
  final VoidCallback onOpenEvidence;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return Row(
        children: [
          IconButton(
            tooltip: 'Back to Home',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Preview',
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: compact ? 17 : 18),
                ),
                if (!compact)
                  Text(
                    'See how your portfolio will look to others.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.tealContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_off_outlined,
                  color: AppColors.teal,
                  size: 16,
                ),
                if (!compact) ...[
                  const SizedBox(width: 5),
                  const Text(
                    'Private preview',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_PortfolioHeaderAction>(
            tooltip: 'Portfolio options',
            onSelected: (action) {
              switch (action) {
                case _PortfolioHeaderAction.editProfile:
                  onEditProfile();
                case _PortfolioHeaderAction.projects:
                  onOpenProjects();
                case _PortfolioHeaderAction.skills:
                  onOpenSkills();
                case _PortfolioHeaderAction.evidence:
                  onOpenEvidence();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _PortfolioHeaderAction.editProfile,
                child: Text('Edit profile'),
              ),
              PopupMenuItem(
                value: _PortfolioHeaderAction.projects,
                child: Text('Manage projects'),
              ),
              PopupMenuItem(
                value: _PortfolioHeaderAction.skills,
                child: Text('Manage skills'),
              ),
              PopupMenuItem(
                value: _PortfolioHeaderAction.evidence,
                child: Text('Private evidence'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSelected,
    child: InkWell(
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppColors.indigo : AppColors.slateGray,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.indigo : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PortfolioActionCard extends StatelessWidget {
  const _PortfolioActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: color.withValues(alpha: .2)),
    ),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            AppIconTile(
              icon: icon,
              size: 32,
              iconSize: 18,
              color: color,
              backgroundColor: AppColors.white.withValues(alpha: .72),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_forward, color: color, size: 16),
          ],
        ),
      ),
    ),
  );
}

class _PortfolioContentView extends StatelessWidget {
  const _PortfolioContentView({
    required this.content,
    required this.onEditProfile,
    required this.onOpenProjects,
    required this.onOpenSkills,
    required this.onOpenRecord,
    required this.onOpenEvidence,
    required this.sectionKeys,
    required this.selectedSection,
    required this.onSelectSection,
    this.onBuildSite,
    this.onBuildResume,
  });

  final PortfolioContent content;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenSkills;
  final ValueChanged<PortfolioRecordType> onOpenRecord;
  final VoidCallback onOpenEvidence;
  final Map<_PortfolioSection, GlobalKey> sectionKeys;
  final _PortfolioSection selectedSection;
  final ValueChanged<_PortfolioSection> onSelectSection;
  final ValueChanged<PortfolioContent>? onBuildSite;
  final ValueChanged<PortfolioContent>? onBuildResume;

  @override
  Widget build(BuildContext context) {
    final suggestions = PortfolioReadiness.evaluate(content);
    final covered = suggestions
        .where((suggestion) => suggestion.isCovered)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.profile.isAvailable && content.profile.value != null)
          _buildProfileHero(context, content.profile.value!)
        else
          _buildProfileState(context, content.profile.isAvailable),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final section in _PortfolioSection.values)
              Expanded(
                child: _SectionTab(
                  key: ValueKey('portfolio-tab-${section.name}'),
                  label: section.label,
                  isSelected: selectedSection == section,
                  onPressed: () => onSelectSection(section),
                ),
              ),
          ],
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        _buildProjectSection(context),
        _buildSkillsSection(context),
        _buildAboutSection(context, content.profile.value),
        _buildActionCards(),
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
        _buildContactSection(context, content.profile.value),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: _ReadinessCard(
            suggestions: suggestions,
            covered: covered,
            onOpen: _openDestination,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileState(BuildContext context, bool isAvailable) => _Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAvailable
              ? 'Add your profile details to build this preview.'
              : 'Your profile could not be loaded. Pull to refresh.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (isAvailable) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.person_outline),
            label: const Text('Edit profile'),
          ),
        ],
      ],
    ),
  );

  Widget _buildProfileHero(BuildContext context, PortfolioProfile profile) {
    final title = profile.displayName.trim().isEmpty
        ? 'Name not added'
        : profile.displayName;
    final headline = profile.headline.trim().isNotEmpty
        ? profile.headline
        : profile.occupationTitle;
    final bio = profile.bio.trim();
    final links = _profileLinks(profile);
    final photoBytes = content.photoBytes.isAvailable
        ? content.photoBytes.value
        : null;
    final photoUrl = content.photoUrl.isAvailable
        ? content.photoUrl.value
        : null;

    Widget avatarPlaceholder() => Container(
      color: AppColors.tealContainer,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline,
        color: AppColors.deepNavy,
        size: 34,
      ),
    );

    final Widget avatar;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      avatar = Image.memory(
        photoBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => avatarPlaceholder(),
      );
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => avatarPlaceholder(),
      );
    } else {
      avatar = avatarPlaceholder();
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepNavy, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -52,
            top: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: .38),
              ),
            ),
          ),
          Positioned(
            left: -55,
            bottom: -100,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.indigo.withValues(alpha: .24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 72, height: 72, child: ClipOval(child: avatar)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (headline.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.white),
                        ),
                      ],
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.white),
                        ),
                      ],
                      if (links.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 0,
                          children: [
                            for (final link in links.take(2))
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: const Size(44, 44),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _openLink(context, link.url),
                                icon: Icon(link.icon, size: 15),
                                label: Text(
                                  link.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (!content.photoUrl.isAvailable &&
                          !content.photoBytes.isAvailable &&
                          profile.photoPath != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Profile photo could not be loaded.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSection(BuildContext context) {
    final projects = content.projects.value ?? const <PortfolioProject>[];
    return _primarySection(
      context,
      section: _PortfolioSection.projects,
      title: 'Featured Projects',
      actionLabel: 'View all',
      onAction: onOpenProjects,
      isAvailable: content.projects.isAvailable,
      hasContent: projects.isNotEmpty,
      emptyMessage: 'Add projects to show the work you have built.',
      child: Column(
        children: [
          for (final project in projects.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildProjectCard(context, project),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, PortfolioProject project) {
    final details = project.summary.trim().isNotEmpty
        ? project.summary
        : project.description.trim().isNotEmpty
        ? project.description
        : project.contribution;
    final repositoryUrl = project.repositoryUrl.trim();
    final demoUrl = project.demoUrl.trim();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightSlate),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProjectThumbnail(project: project),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (details.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (project.technologies.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        for (final technology in project.technologies.take(4))
                          Chip(
                            label: Text(technology),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                  if (repositoryUrl.isNotEmpty || demoUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      children: [
                        if (repositoryUrl.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _openLink(context, repositoryUrl),
                            icon: const Icon(Icons.code, size: 16),
                            label: const Text('Repository'),
                          ),
                        if (demoUrl.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _openLink(context, demoUrl),
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Live Demo'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right,
              color: AppColors.slateGray,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection(BuildContext context) {
    final skills = content.skills.value ?? const <PortfolioSkill>[];
    return _primarySection(
      context,
      section: _PortfolioSection.skills,
      title: 'Skills',
      actionLabel: 'View all',
      onAction: onOpenSkills,
      isAvailable: content.skills.isAvailable,
      hasContent: skills.isNotEmpty,
      emptyMessage: 'Add skills to show the strengths behind your projects.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleSkills = skills.take(3).toList(growable: false);
          final width =
              (constraints.maxWidth - 8 * (visibleSkills.length - 1)) /
              visibleSkills.length;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in visibleSkills)
                SizedBox(
                  width: width,
                  child: _SkillPreviewCard(skill: skill, compact: width < 112),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, PortfolioProfile? profile) {
    final bio = profile?.bio.trim() ?? '';
    return Padding(
      key: sectionKeys[_PortfolioSection.about],
      padding: const EdgeInsets.only(top: 18),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.lightSlate),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEditProfile,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      if (!content.profile.isAvailable)
                        Text(
                          'About information could not be loaded. Pull to refresh.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else if (bio.isEmpty)
                        Text(
                          'Add a short introduction to explain your work.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Text(
                          bio,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.slateGray),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, PortfolioProfile? profile) {
    final links = profile == null
        ? const <_PortfolioLink>[]
        : _profileLinks(profile);
    return _primarySection(
      context,
      section: _PortfolioSection.contact,
      title: 'Contact',
      actionLabel: 'Edit',
      onAction: onEditProfile,
      isAvailable: content.profile.isAvailable,
      hasContent: links.isNotEmpty,
      emptyMessage: 'Add a contact method so people can reach you.',
      child: _Surface(
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final link in links)
              TextButton.icon(
                onPressed: () => _openLink(context, link.url),
                icon: Icon(link.icon, size: 18),
                label: Text(_contactLinkLabel(link)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    if (onBuildResume == null && onBuildSite == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onBuildResume case final onBuildResume?)
              Expanded(
                child: _PortfolioActionCard(
                  icon: Icons.description_outlined,
                  title: 'Generate Resume',
                  description:
                      'Create a resume from your profile and projects.',
                  color: AppColors.indigo,
                  backgroundColor: AppColors.indigoContainer,
                  onPressed: () => onBuildResume(content),
                ),
              ),
            if (onBuildResume != null && onBuildSite != null)
              const SizedBox(width: 10),
            if (onBuildSite case final onBuildSite?)
              Expanded(
                child: _PortfolioActionCard(
                  icon: Icons.auto_awesome,
                  title: 'Generate Portfolio',
                  description: 'Build a professional website preview.',
                  color: AppColors.teal,
                  backgroundColor: AppColors.tealContainer,
                  onPressed: () => onBuildSite(content),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _primarySection(
    BuildContext context, {
    required _PortfolioSection section,
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    required bool isAvailable,
    required bool hasContent,
    required String emptyMessage,
    required Widget child,
  }) => Padding(
    key: sectionKeys[section],
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
        const SizedBox(height: 6),
        if (!isAvailable)
          _Surface(
            child: Text(
              '$title could not be loaded. Pull to refresh.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else if (!hasContent)
          _Surface(
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          child,
      ],
    ),
  );

  List<_PortfolioLink> _profileLinks(PortfolioProfile profile) {
    final links = <_PortfolioLink>[];
    if (profile.contactEmail.trim().isNotEmpty) {
      links.add(
        _PortfolioLink(
          label: 'Email',
          url: Uri(
            scheme: 'mailto',
            path: profile.contactEmail.trim(),
          ).toString(),
          icon: Icons.email_outlined,
        ),
      );
    }
    if (profile.phone.trim().isNotEmpty) {
      links.add(
        _PortfolioLink(
          label: 'Phone',
          url: Uri(scheme: 'tel', path: profile.phone.trim()).toString(),
          icon: Icons.phone_outlined,
        ),
      );
    }
    for (final entry in [
      ('GitHub', profile.githubUrl, Icons.code),
      ('LinkedIn', profile.linkedInUrl, Icons.work_outline),
      ('Upwork', profile.upworkUrl, Icons.work_outline),
      ('JobStreet', profile.jobstreetUrl, Icons.work_outline),
    ]) {
      if (entry.$2.trim().isNotEmpty) {
        links.add(
          _PortfolioLink(
            label: entry.$1,
            url: _withWebScheme(entry.$2),
            icon: entry.$3,
          ),
        );
      }
    }
    final whatsappDigits = profile.whatsAppNumber.replaceAll(RegExp(r'\D'), '');
    if (whatsappDigits.isNotEmpty) {
      links.add(
        _PortfolioLink(
          label: 'WhatsApp',
          url: 'https://wa.me/$whatsappDigits',
          icon: Icons.chat_bubble_outline,
        ),
      );
    }
    for (final link in profile.additionalLinks) {
      if (link.label.trim().isNotEmpty && link.url.trim().isNotEmpty) {
        links.add(
          _PortfolioLink(
            label: link.label.trim(),
            url: _withWebScheme(link.url),
            icon: Icons.open_in_new,
          ),
        );
      }
    }
    return links;
  }

  String _withWebScheme(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return 'https://$trimmed';
    return trimmed;
  }

  String _contactLinkLabel(_PortfolioLink link) {
    final value = switch (Uri.tryParse(link.url)?.scheme) {
      'mailto' => link.url.substring('mailto:'.length),
      'tel' => link.url.substring('tel:'.length),
      _ => link.url,
    };
    return '${link.label}: $value';
  }

  Future<void> _openLink(BuildContext context, String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !const {'http', 'https', 'mailto', 'tel'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This link is invalid and could not be opened.'),
        ),
      );
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No application is available for this link.');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open this link: $error')),
      );
    }
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

class _ProjectThumbnail extends StatelessWidget {
  const _ProjectThumbnail({required this.project});

  final PortfolioProject project;

  @override
  Widget build(BuildContext context) {
    final embedded = project.technologies.any((technology) {
      final normalized = technology.toLowerCase();
      return normalized.contains('esp') ||
          normalized.contains('embedded') ||
          normalized.contains('arduino');
    });
    return Container(
      width: 86,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepNavy, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealAccent.withValues(alpha: .35),
              ),
            ),
          ),
          Icon(
            embedded ? Icons.memory_outlined : Icons.devices_other_outlined,
            color: AppColors.white,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _SkillPreviewCard extends StatelessWidget {
  const _SkillPreviewCard({required this.skill, required this.compact});

  final PortfolioSkill skill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final category = skill.category.toLowerCase();
    final icon = category.contains('database')
        ? Icons.storage_outlined
        : category.contains('embedded')
        ? Icons.memory_outlined
        : Icons.code;
    final iconTile = AppIconTile(
      icon: icon,
      size: 32,
      iconSize: 17,
      color: AppColors.indigo,
      backgroundColor: AppColors.indigoContainer,
    );
    final labels = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          skill.category,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.deepNavy,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          skill.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightSlate),
        borderRadius: BorderRadius.circular(12),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconTile,
                const SizedBox(height: 6),
                SizedBox(width: double.infinity, child: labels),
              ],
            )
          : Row(
              children: [
                iconTile,
                const SizedBox(width: 8),
                Expanded(child: labels),
              ],
            ),
    );
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
  });

  final String title;
  final String subtitle;
  final String detail;

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
