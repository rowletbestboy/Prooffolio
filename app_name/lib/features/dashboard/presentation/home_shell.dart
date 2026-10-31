import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_brand_mark.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../domain/portfolio_progress.dart';
import 'home_profile_avatar.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/domain/project.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../skills/domain/skill.dart';
import '../../portfolio/data/portfolio_record_repository.dart';
import '../../portfolio/data/portfolio_content_repository.dart';
import '../../portfolio/data/portfolio_publication_repository.dart';
import '../../portfolio/domain/portfolio_record.dart';
import '../../portfolio/domain/resume_content.dart';
import '../../portfolio/presentation/portfolio_records_screen.dart';
import '../../portfolio/presentation/portfolio_preview_screen.dart';
import '../../portfolio/presentation/resume_preview_screen.dart';
import '../../portfolio/presentation/portfolio_site_preview.dart';
import '../../evidence/data/evidence_repository.dart';
import '../../evidence/domain/evidence.dart';
import '../../evidence/presentation/evidence_library_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../profile/presentation/profile_background_screen.dart';
import '../../profile/presentation/profile_overview_screen.dart';
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
    this.portfolioContentRepository,
    this.portfolioPublicationRepository,
    this.evidenceRepository,
    this.evidenceFilePicker,
    this.profileRepository,
    this.profileUserId,
    this.profileAccountEmail,
  });

  final Future<void> Function()? onSignOut;
  final ProjectRepository? projectRepository;
  final SkillRepository? skillRepository;
  final PortfolioRecordRepository? portfolioRecordRepository;
  final PortfolioContentRepository? portfolioContentRepository;
  final PortfolioPublicationRepository? portfolioPublicationRepository;
  final EvidenceRepository? evidenceRepository;
  final EvidenceFilePicker? evidenceFilePicker;
  final ProfileBackgroundRepository? profileRepository;
  final String? profileUserId;
  final String? profileAccountEmail;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _homeKey = GlobalKey<_HomePageState>();

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _homeKey.currentState?._reloadHomeData();
  }

  Future<void> _openProfileOverview() async {
    final repository = widget.profileRepository;
    final userId = widget.profileUserId;
    if (repository == null || userId == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileOverviewScreen(
          repository: repository,
          userId: userId,
          skillRepository: widget.skillRepository,
          accountEmail: widget.profileAccountEmail,
          onSignOut: widget.onSignOut,
          onOpenSkills: () {
            Navigator.of(context).pop();
            _selectDestination(2);
          },
        ),
      ),
    );
  }

  Widget _buildPortfolioPreview() => PortfolioPreviewScreen(
    repository: widget.portfolioContentRepository,
    userId: widget.profileUserId,
    onBack: () => _selectDestination(0),
    onEditProfile: () {
      if (widget.profileRepository == null || widget.profileUserId == null) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfileBackgroundScreen(
            repository: widget.profileRepository!,
            userId: widget.profileUserId!,
            accountEmail: widget.profileAccountEmail,
          ),
        ),
      );
    },
    onOpenProjects: () => _selectDestination(1),
    onOpenSkills: () => _selectDestination(2),
    onOpenRecord: (type) async {
      final repository = widget.portfolioRecordRepository;
      if (repository == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              PortfolioRecordsScreen(repository: repository, initialType: type),
        ),
      );
    },
    onOpenEvidence: () async {
      final repository = widget.evidenceRepository;
      if (repository == null) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EvidenceLibraryScreen(
            repository: repository,
            filePicker:
                widget.evidenceFilePicker ?? PlatformEvidenceFilePicker(),
          ),
        ),
      );
    },
    onBuildSite: (content) => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PortfolioSitePreview(
          content: content,
          userId: widget.profileUserId,
          publicationRepository: widget.portfolioPublicationRepository,
        ),
      ),
    ),
    onBuildResume: (content) => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ResumePreviewScreen(
          content: ResumeContent.fromPortfolioContent(content),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final profileRepository = widget.profileRepository;
    final profileUserId = widget.profileUserId;
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
        onSignOut: widget.onSignOut == null
            ? null
            : () => unawaited(widget.onSignOut!()),
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
        onOpenProfile:
            widget.profileRepository == null || widget.profileUserId == null
            ? null
            : _openProfileOverview,
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
          onSignOut: widget.onSignOut == null
              ? null
              : () => unawaited(widget.onSignOut!()),
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
          onSignOut: widget.onSignOut == null
              ? null
              : () => unawaited(widget.onSignOut!()),
        ),
      _buildPortfolioPreview(),
      if (profileRepository != null &&
          profileUserId != null &&
          profileUserId.isNotEmpty)
        ProfileOverviewScreen(
          repository: profileRepository,
          userId: profileUserId,
          skillRepository: widget.skillRepository,
          accountEmail: widget.profileAccountEmail,
          onSignOut: widget.onSignOut,
          onOpenSkills: () => _selectDestination(2),
        )
      else
        _EmptyDestinationPage(
          icon: Icons.person_outline,
          title: 'Profile',
          heading: 'Your profile is not available',
          description:
              'Your profile details will appear here once your account is connected.',
          nextStep:
              'Sign in again or refresh your account to load your profile.',
          iconColor: AppColors.deepNavy,
          iconBackground: AppColors.indigoContainer,
          onSignOut: widget.onSignOut == null
              ? null
              : () => unawaited(widget.onSignOut!()),
        ),
    ];

    final wideLayout = MediaQuery.sizeOf(context).width >= 900;
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
        tooltip: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder_open),
        label: 'Projects',
        tooltip: 'Projects',
      ),
      NavigationDestination(
        icon: Icon(Icons.lightbulb_outline),
        selectedIcon: Icon(Icons.lightbulb),
        label: 'Skills',
        tooltip: 'Skills',
      ),
      NavigationDestination(
        icon: Icon(Icons.public_outlined),
        selectedIcon: Icon(Icons.public),
        label: 'Portfolio',
        tooltip: 'Portfolio',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
        tooltip: 'Profile',
      ),
    ];
    final bottomSafeInset = MediaQuery.viewPaddingOf(context).bottom;
    const navigationHeight = 56.0;
    const navigationBottomSpacing = 12.0;
    return Scaffold(
      body: Stack(
        key: const ValueKey('home-shell-body'),
        children: [
          Positioned.fill(
            child: Row(
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
          ),
          if (!wideLayout)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomSafeInset + navigationBottomSpacing,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    key: const ValueKey('floating-bottom-navigation'),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.softLavender,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepNavy.withValues(alpha: .14),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: NavigationBar(
                        height: navigationHeight,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        indicatorColor: AppColors.indigoContainer,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysHide,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _selectDestination,
                        destinations: destinations,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
    this.onOpenProfile,
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
  final Future<void> Function()? onOpenProfile;
  final Future<void> Function()? onOpenCredentials;
  final Future<void> Function()? onOpenAchievements;
  final Future<void> Function()? onOpenEvidence;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late Future<_HomeData> _homeDataFuture;
  late Future<ProfileBackground?> _profileFuture;
  Future<String?>? _signedPhotoUrlFuture;
  String? _signedPhotoPath;
  ProfileBackgroundRepository? _signedPhotoRepository;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
    _profileFuture = _loadProfile();
  }

  Future<ProfileBackground?> _loadProfile() {
    final repository = widget.profileRepository;
    final userId = widget.profileUserId;
    if (repository == null || userId == null) {
      return Future<ProfileBackground?>.value(null);
    }
    return repository.loadProfile(userId);
  }

  Future<_HomeData> _loadHomeData() async {
    final projectsFuture = widget.projectRepository == null
        ? Future<List<Project>?>.value(null)
        : widget.projectRepository!.listProjects();
    final skillsFuture = widget.skillRepository == null
        ? Future<List<Skill>?>.value(null)
        : widget.skillRepository!.listSkills();
    final certificationsFuture = widget.portfolioRecordRepository == null
        ? Future<List<PortfolioRecord>?>.value(null)
        : widget.portfolioRecordRepository!.listRecords(
            PortfolioRecordType.certification,
          );
    final achievementsFuture = widget.portfolioRecordRepository == null
        ? Future<List<PortfolioRecord>?>.value(null)
        : widget.portfolioRecordRepository!.listRecords(
            PortfolioRecordType.achievement,
          );
    final evidenceFuture = widget.evidenceRepository == null
        ? Future<List<EvidenceRecord>?>.value(null)
        : widget.evidenceRepository!.listEvidence();
    final results = await Future.wait<Object?>([
      projectsFuture,
      skillsFuture,
      certificationsFuture,
      achievementsFuture,
      evidenceFuture,
    ]);
    final projects = results[0] as List<Project>?;
    final skills = results[1] as List<Skill>?;
    final certifications = results[2] as List<PortfolioRecord>?;
    final achievements = results[3] as List<PortfolioRecord>?;
    final evidence = results[4] as List<EvidenceRecord>?;
    return _HomeData(
      projects: projects,
      counts: _ProgressCounts(
        projects: projects?.length,
        skills: skills?.length,
        certifications: certifications?.length,
        achievements: achievements?.length,
        evidence: evidence?.length,
      ),
    );
  }

  Future<String?>? _signedPhotoUrl(ProfileBackground? profile) {
    final path = profile?.photoPath?.trim();
    final repository = widget.profileRepository;
    if (path == null || path.isEmpty || repository == null) return null;
    if (_signedPhotoPath != path ||
        !identical(_signedPhotoRepository, repository)) {
      _signedPhotoPath = path;
      _signedPhotoRepository = repository;
      _signedPhotoUrlFuture = repository.createProfilePhotoSignedUrl(path);
    }
    return _signedPhotoUrlFuture;
  }

  Future<void> _refresh() async {
    final homeDataFuture = _loadHomeData();
    final profileFuture = _loadProfile();
    setState(() {
      _homeDataFuture = homeDataFuture;
      _profileFuture = profileFuture;
      _signedPhotoPath = null;
      _signedPhotoRepository = null;
      _signedPhotoUrlFuture = null;
    });
    await Future.wait<Object?>([homeDataFuture, profileFuture]).then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Home dashboard',
            context: ErrorDescription('while refreshing saved portfolio data'),
          ),
        );
      },
    );
  }

  void _reloadHomeData() {
    setState(() {
      _homeDataFuture = _loadHomeData();
      _profileFuture = _loadProfile();
      _signedPhotoPath = null;
      _signedPhotoRepository = null;
      _signedPhotoUrlFuture = null;
    });
  }

  void _reloadProfile() {
    setState(() {
      _profileFuture = _loadProfile();
      _signedPhotoPath = null;
      _signedPhotoRepository = null;
      _signedPhotoUrlFuture = null;
    });
  }

  Future<void> _openAndRefresh(Future<void> Function()? action) async {
    if (action == null) return;
    await action();
    if (!mounted) return;
    _reloadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: FutureBuilder<ProfileBackground?>(
              future: _profileFuture,
              builder: (context, profileSnapshot) => FutureBuilder<_HomeData>(
                future: _homeDataFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final profile = profileSnapshot.data;
                  final profileSourceAvailable =
                      widget.profileRepository != null &&
                      widget.profileUserId != null;
                  final profileLoaded =
                      profileSnapshot.connectionState == ConnectionState.done &&
                      !profileSnapshot.hasError;
                  final progress = data?.progress(
                    profile: profile,
                    profileSourceAvailable:
                        profileSourceAvailable && profileLoaded,
                  );
                  final avatar = _buildProfileAvatar(profile);
                  final isLoading =
                      (snapshot.connectionState != ConnectionState.done &&
                          !snapshot.hasError) ||
                      (profileSourceAvailable &&
                          profileSnapshot.connectionState !=
                              ConnectionState.done &&
                          !profileSnapshot.hasError);
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      pageGutter,
                      18,
                      pageGutter,
                      AppTheme.floatingNavigationContentInset +
                          MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      _BrandHeader(
                        avatar: avatar,
                        onSignOut: widget.onSignOut,
                        showTagline: true,
                      ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        const _HomeLoadState()
                      else if (snapshot.hasError) ...[
                        _HomeErrorState(onRetry: _reloadHomeData),
                        if (profileSourceAvailable) ...[
                          const SizedBox(height: 16),
                          ProfileCompletionReminder(
                            profile: profile,
                            isLoading:
                                profileSnapshot.connectionState !=
                                    ConnectionState.done &&
                                !profileSnapshot.hasError,
                            hasError: profileSnapshot.hasError,
                            onOpenProfile: () => unawaited(
                              _openAndRefresh(widget.onOpenProfile),
                            ),
                            onRetry: _reloadProfile,
                          ),
                        ],
                      ] else if (data != null) ...[
                        _GreetingHero(profile: profile),
                        const SizedBox(height: 12),
                        _PortfolioProgressCard(
                          progress: progress,
                          onRetry: _reloadHomeData,
                        ),
                        const SizedBox(height: 9),
                        _ProgressOverview(
                          counts: data.counts,
                          onProjects: widget.onOpenProjects,
                          onSkills: widget.onOpenSkills,
                          onCredentials: widget.onOpenCredentials == null
                              ? null
                              : () => unawaited(
                                  _openAndRefresh(widget.onOpenCredentials),
                                ),
                          onAchievements: widget.onOpenAchievements == null
                              ? null
                              : () => unawaited(
                                  _openAndRefresh(widget.onOpenAchievements),
                                ),
                          onEvidence: widget.onOpenEvidence == null
                              ? null
                              : () => unawaited(
                                  _openAndRefresh(widget.onOpenEvidence),
                                ),
                        ),
                        const SizedBox(height: 13),
                        _ShortcutGrid(
                          onAddProject: widget.onBrowseProjects,
                          onManageSkills: widget.onOpenSkills,
                          onGenerateResume: widget.onOpenPortfolio,
                          onPortfolio: widget.onOpenPortfolio,
                        ),
                        if (profileSourceAvailable) ...[
                          const SizedBox(height: 16),
                          ProfileCompletionReminder(
                            profile: profile,
                            isLoading:
                                profileSnapshot.connectionState !=
                                    ConnectionState.done &&
                                !profileSnapshot.hasError,
                            hasError: profileSnapshot.hasError,
                            onOpenProfile: () => unawaited(
                              _openAndRefresh(widget.onOpenProfile),
                            ),
                            onRetry: _reloadProfile,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _RecentProjectsSection(
                          projects: data.projects,
                          onBrowseProjects: widget.onBrowseProjects,
                        ),
                        const SizedBox(height: 18),
                        _ResumeCallout(onOpenPortfolio: widget.onOpenPortfolio),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.deepNavy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ProfileBackground? profile) {
    final displayName = profile?.displayName ?? '';
    final photoUrlFuture = _signedPhotoUrl(profile);
    final onTap = widget.onOpenProfile == null
        ? null
        : () => unawaited(_openAndRefresh(widget.onOpenProfile));
    if (photoUrlFuture == null) {
      return HomeProfileAvatar(
        displayName: displayName,
        photoUrl: null,
        onTap: onTap,
      );
    }
    return FutureBuilder<String?>(
      future: photoUrlFuture,
      builder: (context, snapshot) => HomeProfileAvatar(
        displayName: displayName,
        photoUrl: snapshot.data,
        onTap: onTap,
      ),
    );
  }
}

class _HomeData {
  const _HomeData({required this.projects, required this.counts});

  final List<Project>? projects;
  final _ProgressCounts counts;

  PortfolioProgress? progress({
    required ProfileBackground? profile,
    required bool profileSourceAvailable,
  }) => profileSourceAvailable
      ? calculatePortfolioProgress(
          profile: profile,
          projectCount: counts.projects,
          skillCount: counts.skills,
          certificationCount: counts.certifications,
          achievementCount: counts.achievements,
          evidenceCount: counts.evidence,
        )
      : null;
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
}

class _HomeLoadState extends StatelessWidget {
  const _HomeLoadState();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Loading your saved portfolio…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.indigo,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load portfolio data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _GreetingHero extends StatelessWidget {
  const _GreetingHero({required this.profile});

  final ProfileBackground? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName.trim() ?? '';
    final hour = DateTime.now().hour;
    final greeting = switch (hour) {
      < 12 => 'Good morning,',
      < 17 => 'Good afternoon,',
      _ => 'Good evening,',
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final textWidth = constraints.maxWidth - (isCompact ? 128 : 130);
        final nameFontSize = name.length > 25
            ? (isCompact ? 17.0 : 18.0)
            : (isCompact ? 22.0 : 24.0);
        final nameMaxLines = name.length > 25 ? (isCompact ? 4 : 3) : 2;
        final noteWidth = isCompact ? 88.0 : 98.0;
        final laptopWidth = isCompact ? 86.0 : 104.0;
        final laptopScreenWidth = isCompact ? 66.0 : 78.0;
        final laptopScreenHeight = isCompact ? 44.0 : 48.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 168),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF102757),
                  Color(0xFF0C214F),
                  Color(0xFF062C5A),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: -55,
                  child: Container(
                    width: 184,
                    height: 112,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C607A),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Positioned(
                  right: -12,
                  bottom: -72,
                  child: Container(
                    width: 152,
                    height: 94,
                    decoration: BoxDecoration(
                      color: const Color(0xFF087C86),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: SizedBox(
                    width: textWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Welcome to' : greeting,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.white,
                                fontSize: isCompact ? 22 : 24,
                                height: 1.28,
                                letterSpacing: -0.7,
                              ),
                        ),
                        Text(
                          name.isEmpty ? 'Prooffolio' : name,
                          maxLines: nameMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.tealAccent,
                                fontSize: nameFontSize,
                                height: 1.28,
                                letterSpacing: -0.7,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Build a portfolio that shows what you can do.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFFE4EBFB),
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 17,
                  right: 12,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: noteWidth,
                      child: Text(
                        'Real projects.\nReal skills.\nReal opportunities.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.white,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isCompact)
                  Positioned(
                    right: 128,
                    bottom: 14,
                    child: const ExcludeSemantics(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF21D6B3),
                        size: 27,
                      ),
                    ),
                  ),
                Positioned(
                  right: isCompact ? 14 : 24,
                  bottom: 10,
                  child: ExcludeSemantics(
                    child: Transform.rotate(
                      angle: -0.07,
                      child: SizedBox(
                        width: laptopWidth,
                        height: 62,
                        child: Stack(
                          children: [
                            Positioned(
                              left: (laptopWidth - laptopScreenWidth) / 2,
                              top: 0,
                              child: Container(
                                width: laptopScreenWidth,
                                height: laptopScreenHeight,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2145BA),
                                  border: Border.all(
                                    color: const Color(0xFF3148DF),
                                    width: 4,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66101E57),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.public_outlined,
                                  color: Color(0xFF9FB9FF),
                                  size: 22,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: laptopWidth,
                                height: 9,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9FBAFF),
                                      Color(0xFFD6E5FF),
                                      Color(0xFF698CE8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioProgressCard extends StatelessWidget {
  const _PortfolioProgressCard({required this.progress, required this.onRetry});

  final PortfolioProgress? progress;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.track_changes_outlined,
                        color: AppColors.teal,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'PORTFOLIO COMPLETION',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slateGray,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (progress case final progress?) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${progress.percentage}%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.deepNavy,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.indigoContainer,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${progress.completedMilestones} of ${progress.totalMilestones} foundational items complete',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Portfolio progress is unavailable',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Some required saved data could not be found.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 90,
                constraints: const BoxConstraints(minHeight: 73),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.checklist_outlined,
                      color: AppColors.teal,
                      size: 18,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "You're on the right track!",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.teal,
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({
    required this.onAddProject,
    required this.onManageSkills,
    required this.onGenerateResume,
    required this.onPortfolio,
  });

  final VoidCallback onAddProject;
  final VoidCallback onManageSkills;
  final VoidCallback onGenerateResume;
  final VoidCallback onPortfolio;

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      _Shortcut(
        label: 'Add Project',
        icon: Icons.add_box_outlined,
        color: AppColors.indigo,
        backgroundColor: AppColors.indigoContainer,
        onTap: onAddProject,
      ),
      _Shortcut(
        label: 'Manage Skills',
        icon: Icons.lightbulb_outline,
        color: AppColors.teal,
        backgroundColor: AppColors.tealContainer,
        onTap: onManageSkills,
      ),
      _Shortcut(
        label: 'Generate Resume',
        icon: Icons.description_outlined,
        color: const Color(0xFF328BE6),
        backgroundColor: const Color(0xFFE2F2FF),
        onTap: onGenerateResume,
      ),
      _Shortcut(
        label: 'Portfolio',
        icon: Icons.public_outlined,
        color: AppColors.indigo,
        backgroundColor: const Color(0xFFEDE8FF),
        onTap: onPortfolio,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final shortcut in shortcuts)
              SizedBox(
                width: width,
                child: _ShortcutTile(shortcut: shortcut),
              ),
          ],
        );
      },
    );
  }
}

class _Shortcut {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});

  final _Shortcut shortcut;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: shortcut.backgroundColor,
    child: InkWell(
      onTap: shortcut.onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 89,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(
                icon: shortcut.icon,
                color: AppColors.white,
                backgroundColor: shortcut.color,
                size: 29,
                iconSize: 15,
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shortcut.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.deepNavy,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.deepNavy,
                    size: 11,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RecentProjectsSection extends StatelessWidget {
  const _RecentProjectsSection({
    required this.projects,
    required this.onBrowseProjects,
  });

  final List<Project>? projects;
  final VoidCallback onBrowseProjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = projects == null ? <Project>[] : [...projects!]
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeading(title: 'Recent projects')),
            TextButton(
              onPressed: onBrowseProjects,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (projects == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Recent projects are unavailable.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const AppIconTile(
                    icon: Icons.folder_open_outlined,
                    color: AppColors.indigo,
                    backgroundColor: AppColors.indigoContainer,
                    size: 42,
                    iconSize: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No projects yet. Add one to show your work here.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final project in recent.take(3)) ...[
            _RecentProjectTile(project: project, onTap: onBrowseProjects),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = switch (project.status) {
      ProjectStatus.inProgress => 'In progress',
      ProjectStatus.completed => 'Completed',
      ProjectStatus.paused => 'Paused',
    };
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const AppIconTile(
          icon: Icons.folder_outlined,
          color: AppColors.indigo,
          backgroundColor: AppColors.indigoContainer,
          size: 42,
          iconSize: 21,
        ),
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ResumeCallout extends StatelessWidget {
  const _ResumeCallout({required this.onOpenPortfolio});

  final VoidCallback onOpenPortfolio;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.tealContainer,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Build a resume from your portfolio',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.deepNavy),
        ),
        const SizedBox(height: 6),
        Text(
          'Preview how your saved experience comes together.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onOpenPortfolio,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Open resume options'),
        ),
      ],
    ),
  );
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
    final metrics = <_ProgressMetric>[
      _ProgressMetric(
        label: 'Projects',
        shortLabel: 'Projects',
        count: counts.projects,
        onTap: onProjects,
      ),
      _ProgressMetric(
        label: 'Skills',
        shortLabel: 'Skills',
        count: counts.skills,
        onTap: onSkills,
      ),
      _ProgressMetric(
        label: 'Certifications',
        shortLabel: 'Certs',
        count: counts.certifications,
        onTap: onCredentials,
      ),
      _ProgressMetric(
        label: 'Achievements',
        shortLabel: 'Awards',
        count: counts.achievements,
        onTap: onAchievements,
      ),
      _ProgressMetric(
        label: 'Evidence',
        shortLabel: 'Evidence',
        count: counts.evidence,
        onTap: onEvidence,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        const spacing = 5.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _ProgressMetricTile(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressMetric {
  const _ProgressMetric({
    required this.label,
    required this.shortLabel,
    required this.count,
    required this.onTap,
  });

  final String label;
  final String shortLabel;
  final int? count;
  final VoidCallback? onTap;
}

class _ProgressMetricTile extends StatelessWidget {
  const _ProgressMetricTile({required this.metric});

  final _ProgressMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${metric.label}: ${metric.count?.toString() ?? 'unavailable'}',
      button: metric.onTap != null,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: metric.onTap,
          borderRadius: BorderRadius.circular(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
            child: Column(
              children: [
                Text(
                  metric.count?.toString() ?? '—',
                  maxLines: 1,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.deepNavy,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  metric.shortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slateGray,
                    fontSize: 8,
                    height: 1.1,
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
            padding: EdgeInsets.fromLTRB(
              24,
              18,
              24,
              AppTheme.floatingNavigationContentInset +
                  MediaQuery.viewPaddingOf(context).bottom,
            ),
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
  const _BrandHeader({this.onSignOut, this.avatar, this.showTagline = false});

  final VoidCallback? onSignOut;
  final Widget? avatar;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showTagline) ...[
          const SizedBox(width: 96, height: 54, child: AppBrandMark()),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your skills. Your work. Your proof.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slateGray,
                fontSize: 9,
                height: 1.25,
              ),
            ),
          ),
        ] else ...[
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
        ],
        if (avatar case final avatar?) ...[const SizedBox(width: 8), avatar],
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
