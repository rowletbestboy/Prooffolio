import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/presentation/projects_screen.dart';
import '../../portfolio/data/portfolio_record_repository.dart';
import '../../portfolio/presentation/portfolio_records_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_background_screen.dart';
import '../../skills/data/skill_repository.dart';
import '../../skills/presentation/skills_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.onSignOut,
    this.projectRepository,
    this.skillRepository,
    this.portfolioRecordRepository,
    this.profileRepository,
    this.profileUserId,
  });

  final VoidCallback? onSignOut;
  final ProjectRepository? projectRepository;
  final SkillRepository? skillRepository;
  final PortfolioRecordRepository? portfolioRecordRepository;
  final ProfileBackgroundRepository? profileRepository;
  final String? profileUserId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        onAddProject: () => _selectDestination(1),
        onSignOut: widget.onSignOut,
        onOpenCredentials: widget.portfolioRecordRepository == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PortfolioRecordsScreen(
                    repository: widget.portfolioRecordRepository!,
                  ),
                ),
              ),
        onEditProfile:
            widget.profileRepository == null || widget.profileUserId == null
            ? null
            : () => Navigator.of(context).push(
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

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
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
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.onAddProject,
    this.onSignOut,
    this.onEditProfile,
    this.onOpenCredentials,
  });

  final VoidCallback onAddProject;
  final VoidCallback? onSignOut;
  final VoidCallback? onEditProfile;
  final VoidCallback? onOpenCredentials;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandHeader(
                  onSignOut: onSignOut,
                  onEditProfile: onEditProfile,
                ),
                const SizedBox(height: 36),
                Text(
                  'Your work, connected to proof.',
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Share a project, a course you are taking, or experience '
                  'from work, volunteering, care, and independent practice.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                const _EvidenceTrail(),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAddProject,
                    icon: const Icon(Icons.add),
                    label: const Text('Add your first project'),
                  ),
                ),
                if (onOpenCredentials != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onOpenCredentials,
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Certifications and achievements'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Your portfolio can grow from any part of your life and work.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceTrail extends StatelessWidget {
  const _EvidenceTrail();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightSlate),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your evidence trail', style: textTheme.titleMedium),
          const SizedBox(height: 18),
          Semantics(
            label: 'Project connected to a skill, connected to evidence',
            child: const Row(
              children: [
                _EvidenceStep(
                  icon: Icons.folder_outlined,
                  label: 'Project',
                  color: AppColors.deepNavy,
                  background: AppColors.indigoContainer,
                ),
                _TrailConnector(),
                _EvidenceStep(
                  icon: Icons.lightbulb_outline,
                  label: 'Skill',
                  color: AppColors.indigo,
                  background: AppColors.indigoContainer,
                ),
                _TrailConnector(),
                _EvidenceStep(
                  icon: Icons.link,
                  label: 'Evidence',
                  color: AppColors.teal,
                  background: AppColors.tealContainer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _TrailConnector extends StatelessWidget {
  const _TrailConnector();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: 22, left: 8, right: 8),
        child: Divider(),
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
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandHeader(onSignOut: onSignOut),
                const SizedBox(height: 32),
                Text(title, style: textTheme.headlineMedium),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                ),
                const SizedBox(height: 24),
                Text(heading, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(description, style: textTheme.bodyLarge),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.lightSlate),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(nextStep, style: textTheme.bodyMedium),
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
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'P',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('Prooffolio', style: Theme.of(context).textTheme.titleLarge),
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
