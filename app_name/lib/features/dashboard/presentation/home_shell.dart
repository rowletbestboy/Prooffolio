import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../skills/domain/skill.dart';
import '../../portfolio/data/portfolio_record_repository.dart';
import '../../portfolio/domain/portfolio_record.dart';
import '../../portfolio/presentation/portfolio_records_screen.dart';
import '../../evidence/data/evidence_repository.dart';
import '../../evidence/domain/evidence.dart';
import '../../evidence/presentation/evidence_library_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/profile_background_screen.dart';
import 'profile_completion_reminder.dart';
import '../../skills/data/skill_repository.dart';
import '../../skills/presentation/skills_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.onSignOut,
    this.projectRepository,
    this.skillRepository,
    this.portfolioRecordRepository,
    this.evidenceRepository,
    this.evidenceFilePicker,
    this.profileRepository,
    this.profileUserId,
  });

  final VoidCallback? onSignOut;
  final ProjectRepository? projectRepository;
  final SkillRepository? skillRepository;
  final PortfolioRecordRepository? portfolioRecordRepository;
  final EvidenceRepository? evidenceRepository;
  final EvidenceFilePicker? evidenceFilePicker;
  final ProfileBackgroundRepository? profileRepository;
  final String? profileUserId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _homeKey = GlobalKey<_HomePageState>();

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _homeKey.currentState?._reloadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        key: _homeKey,
        onBrowseProjects: () => _selectDestination(1),
        onOpenProjects: () => _selectDestination(1),
        onOpenSkills: () => _selectDestination(2),
        onOpenPortfolio: () => _selectDestination(3),
        projectRepository: widget.projectRepository,
        skillRepository: widget.skillRepository,
        portfolioRecordRepository: widget.portfolioRecordRepository,
        evidenceRepository: widget.evidenceRepository,
        profileRepository: widget.profileRepository,
        profileUserId: widget.profileUserId,
        onSignOut: widget.onSignOut,
        onOpenCredentials: widget.portfolioRecordRepository == null
            ? null
            : () async => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortfolioRecordsScreen(
                    repository: widget.portfolioRecordRepository!,
                  ),
                ),
              ),
        onOpenAchievements: widget.portfolioRecordRepository == null
            ? null
            : () async => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortfolioRecordsScreen(
                    repository: widget.portfolioRecordRepository!,
                    initialType: PortfolioRecordType.achievement,
                  ),
                ),
              ),
        onOpenEvidence: widget.evidenceRepository == null
            ? null
            : () async => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => EvidenceLibraryScreen(
                    repository: widget.evidenceRepository!,
                    filePicker:
                        widget.evidenceFilePicker ??
                        PlatformEvidenceFilePicker(),
                  ),
                ),
              ),
        onEditProfile:
            widget.profileRepository == null || widget.profileUserId == null
            ? null
            : () async => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileBackgroundScreen(
                    repository: widget.profileRepository!,
                    userId: widget.profileUserId!,
                  ),
                ),
              ),
      ),
      if (widget.projectRepository case final repository?)
        ProjectsScreen(repository: repository)
      else
        _EmptyDestinationPage(
          icon: Icons.folder_outlined,
          title: 'Projects',
          heading: 'No projects yet',
          description:
              'Projects will hold what you built, the part you contributed, and links to the work.',
          nextStep:
              'Start with a project you can explain clearly. Project entry is the next feature to add.',
          iconColor: AppColors.deepNavy,
          iconBackground: AppColors.indigoContainer,
          onSignOut: widget.onSignOut,
        ),
      if (widget.skillRepository case final repository?)
        SkillsScreen(
          repository: repository,
          projectRepository: widget.projectRepository,
        )
      else
        _EmptyDestinationPage(
          icon: Icons.lightbulb_outline,
          title: 'Skills',
          heading: 'No skills yet',
          description:
              'Skills become more useful when they connect to a project and evidence of your work.',
          nextStep:
              'Add projects first, then connect the skills you used. Skill tracking is coming in a later step.',
          iconColor: AppColors.indigo,
          iconBackground: AppColors.indigoContainer,
          onSignOut: widget.onSignOut,
        ),
      _EmptyDestinationPage(
        icon: Icons.public_outlined,
        title: 'Portfolio',
        heading: 'Nothing public yet',
        description:
            'You will choose which projects, skills, and evidence visitors can see before publishing.',
        nextStep:
            'Build your project record first. Portfolio preview and sharing come after that.',
        iconColor: AppColors.teal,
        iconBackground: AppColors.tealContainer,
        onSignOut: widget.onSignOut,
      ),
    ];

    final wideLayout = MediaQuery.sizeOf(context).width >= 900;
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder_open),
        label: 'Projects',
      ),
      NavigationDestination(
        icon: Icon(Icons.lightbulb_outline),
        selectedIcon: Icon(Icons.lightbulb),
        label: 'Skills',
      ),
      NavigationDestination(
        icon: Icon(Icons.public_outlined),
        selectedIcon: Icon(Icons.public),
        label: 'Portfolio',
      ),
    ];
    return Scaffold(
      body: Row(
        children: [
          if (wideLayout)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: wideLayout
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _selectDestination,
              destinations: destinations,
            ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({
    super.key,
    required this.onBrowseProjects,
    required this.onOpenProjects,
    required this.onOpenSkills,
    required this.onOpenPortfolio,
    required this.projectRepository,
    required this.skillRepository,
    required this.portfolioRecordRepository,
    required this.evidenceRepository,
    this.onSignOut,
    this.profileRepository,
    this.profileUserId,
    this.onEditProfile,
    this.onOpenCredentials,
    this.onOpenAchievements,
    this.onOpenEvidence,
  });

  final VoidCallback onBrowseProjects;
  final VoidCallback onOpenProjects;
  final VoidCallback onOpenSkills;
  final VoidCallback onOpenPortfolio;
  final ProjectRepository? projectRepository;
  final SkillRepository? skillRepository;
  final PortfolioRecordRepository? portfolioRecordRepository;
  final EvidenceRepository? evidenceRepository;
  final ProfileBackgroundRepository? profileRepository;
  final String? profileUserId;
  final VoidCallback? onSignOut;
  final Future<void> Function()? onEditProfile;
  final Future<void> Function()? onOpenCredentials;
  final Future<void> Function()? onOpenAchievements;
  final Future<void> Function()? onOpenEvidence;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late Future<_ProgressCounts> _countsFuture;
  late Future<ProfileBackground?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
    _profileFuture = _loadProfile();
  }

  Future<ProfileBackground?> _loadProfile() async {
    final repository = widget.profileRepository;
    final userId = widget.profileUserId;
    if (repository == null || userId == null) return null;
    return repository.loadProfile(userId);
  }

  Future<int?> _count<T>(Future<List<T>> Function()? load) async {
    if (load == null) return null;
    try {
      return (await load()).length;
    } catch (_) {
      return null;
    }
  }

  Future<_ProgressCounts> _loadCounts() async {
    final counts = await Future.wait<int?>([
      _count<Project>(widget.projectRepository?.listProjects),
      _count<Skill>(widget.skillRepository?.listSkills),
      _count<PortfolioRecord>(
        widget.portfolioRecordRepository == null
            ? null
            : () => widget.portfolioRecordRepository!.listRecords(
                PortfolioRecordType.certification,
              ),
      ),
      _count<PortfolioRecord>(
        widget.portfolioRecordRepository == null
            ? null
            : () => widget.portfolioRecordRepository!.listRecords(
                PortfolioRecordType.achievement,
              ),
      ),
      _count<EvidenceRecord>(widget.evidenceRepository?.listEvidence),
    ]);
    return _ProgressCounts(
      projects: counts[0],
      skills: counts[1],
      certifications: counts[2],
      achievements: counts[3],
      evidence: counts[4],
    );
  }

  Future<void> _refresh() async {
    setState(() => _countsFuture = _loadCounts());
    await _countsFuture;
  }

  void _reloadCounts() {
    setState(() {
      _countsFuture = _loadCounts();
    });
    _reloadProfile();
  }

  void _reloadProfile() {
    if (widget.profileRepository == null || widget.profileUserId == null) {
      return;
    }
    setState(() => _profileFuture = _loadProfile());
  }

  Future<void> _openAndRefresh(Future<void> Function()? action) async {
    if (action == null) return;
    await action();
    if (!mounted) return;
    await _refresh();
    _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pageGutter, 18, pageGutter, 32),
              children: [
                _BrandHeader(
                  onSignOut: widget.onSignOut,
                  onEditProfile: widget.onEditProfile == null
                      ? null
                      : () => _openAndRefresh(widget.onEditProfile),
                ),
                if (widget.profileRepository != null &&
                    widget.profileUserId != null) ...[
                  const SizedBox(height: 20),
                  FutureBuilder<ProfileBackground?>(
                    future: _profileFuture,
                    builder: (context, snapshot) => ProfileCompletionReminder(
                      profile: snapshot.data,
                      isLoading:
                          snapshot.connectionState != ConnectionState.done &&
                          !snapshot.hasError,
                      hasError: snapshot.hasError,
                      onOpenProfile: () =>
                          unawaited(_openAndRefresh(widget.onEditProfile)),
                      onRetry: _reloadProfile,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Text('Your progress', style: textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Build a clear picture of your work, one piece at a time.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                FutureBuilder<_ProgressCounts>(
                  future: _countsFuture,
                  builder: (context, snapshot) => _ProgressOverview(
                    counts: snapshot.data ?? const _ProgressCounts(),
                    onProjects: widget.onOpenProjects,
                    onSkills: widget.onOpenSkills,
                    onCredentials: widget.onOpenCredentials == null
                        ? null
                        : () => _openAndRefresh(widget.onOpenCredentials),
                    onAchievements: widget.onOpenAchievements == null
                        ? null
                        : () => _openAndRefresh(widget.onOpenAchievements),
                    onEvidence: widget.onOpenEvidence == null
                        ? null
                        : () => _openAndRefresh(widget.onOpenEvidence),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: widget.onBrowseProjects,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('View projects'),
                ),
                if (widget.onOpenEvidence != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openAndRefresh(widget.onOpenEvidence),
                    icon: const Icon(Icons.link_outlined),
                    label: const Text('Evidence library'),
                  ),
                ],
                if (widget.onOpenCredentials != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _openAndRefresh(widget.onOpenCredentials),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Certifications and achievements'),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.indigoContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppColors.indigo,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your portfolio stays private until you choose what to share.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCounts {
  const _ProgressCounts({
    this.projects,
    this.skills,
    this.certifications,
    this.achievements,
    this.evidence,
  });

  final int? projects;
  final int? skills;
  final int? certifications;
  final int? achievements;
  final int? evidence;

  int? get total =>
      [
        projects,
        skills,
        certifications,
        achievements,
        evidence,
      ].every((count) => count != null)
      ? projects! + skills! + certifications! + achievements! + evidence!
      : null;
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({
    required this.counts,
    required this.onProjects,
    required this.onSkills,
    required this.onCredentials,
    required this.onAchievements,
    required this.onEvidence,
  });

  final _ProgressCounts counts;
  final VoidCallback onProjects;
  final VoidCallback onSkills;
  final VoidCallback? onCredentials;
  final VoidCallback? onAchievements;
  final VoidCallback? onEvidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = <_ProgressMetric>[
      _ProgressMetric(
        label: 'Projects',
        count: counts.projects,
        icon: Icons.work_outline,
        color: AppColors.indigo,
        backgroundColor: AppColors.indigoContainer,
        onTap: onProjects,
      ),
      _ProgressMetric(
        label: 'Skills',
        count: counts.skills,
        icon: Icons.lightbulb_outline,
        color: AppColors.teal,
        backgroundColor: AppColors.tealContainer,
        onTap: onSkills,
      ),
      _ProgressMetric(
        label: 'Certifications',
        count: counts.certifications,
        icon: Icons.workspace_premium_outlined,
        color: AppColors.indigo,
        backgroundColor: AppColors.indigoContainer,
        onTap: onCredentials,
      ),
      _ProgressMetric(
        label: 'Achievements',
        count: counts.achievements,
        icon: Icons.emoji_events_outlined,
        color: AppColors.amber,
        backgroundColor: AppColors.amberContainer,
        onTap: onAchievements,
      ),
      _ProgressMetric(
        label: 'Evidence',
        count: counts.evidence,
        icon: Icons.attach_file_outlined,
        color: AppColors.teal,
        backgroundColor: AppColors.tealContainer,
        onTap: onEvidence,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.indigoBright,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counts.total?.toString() ?? '—',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.white,
                        fontSize: 38,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'saved portfolio entries',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const AppIconTile(
                icon: Icons.auto_awesome_outlined,
                color: AppColors.white,
                backgroundColor: Color(0x33FFFFFF),
                size: 54,
                iconSize: 27,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640
                ? 3
                : constraints.maxWidth < 360
                ? 1
                : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: width,
                    child: _ProgressMetricTile(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProgressMetric {
  const _ProgressMetric({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final int? count;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;
}

class _ProgressMetricTile extends StatelessWidget {
  const _ProgressMetricTile({required this.metric});

  final _ProgressMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppIconTile(
                icon: metric.icon,
                color: metric.color,
                backgroundColor: metric.backgroundColor,
                size: 44,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slateGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.count?.toString() ?? '—',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDestinationPage extends StatelessWidget {
  const _EmptyDestinationPage({
    required this.icon,
    required this.title,
    required this.heading,
    required this.description,
    required this.nextStep,
    required this.iconColor,
    required this.iconBackground,
    this.onSignOut,
  });

  final IconData icon;
  final String title;
  final String heading;
  final String description;
  final String nextStep;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandHeader(onSignOut: onSignOut),
                const SizedBox(height: 32),
                Text(title, style: textTheme.headlineMedium),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.lightSlate),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconTile(
                        icon: icon,
                        color: iconColor,
                        backgroundColor: iconBackground,
                        size: 56,
                        iconSize: 27,
                      ),
                      const SizedBox(height: 20),
                      Text(heading, style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(description, style: textTheme.bodyLarge),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(nextStep, style: textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.onSignOut, this.onEditProfile});

  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppBrandMark(compact: true),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Prooffolio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Spacer(),
        if (onEditProfile case final onEditProfile?)
          IconButton(
            tooltip: 'Profile and background',
            onPressed: onEditProfile,
            icon: const Icon(Icons.person_outline),
          ),
        if (onSignOut case final onSignOut?)
          IconButton(
            tooltip: 'Sign out',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_outlined),
          ),
      ],
    );
  }
}
