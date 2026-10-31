import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<Project>> _projectsFuture;
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  String _query = '';
  ProjectPublicationStatus? _publicationFilter;

  @override
  void initState() {
    super.initState();
    _projectsFuture = widget.repository.listProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _projectsFuture = widget.repository.listProjects();
    });
  }

  Future<void> _addProject() async {
    final project = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) => ProjectFormScreen(repository: widget.repository),
      ),
    );
    if (project != null) _reload();
  }

  Future<void> _openProject(Project project) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(
          project: project,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Projects'),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ProjectLoadError(onRetry: _reload);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snapshot.data ?? const <Project>[];
          if (projects.isEmpty) {
            return _EmptyProjectsState(onAddProject: _addProject);
          }
          final filteredProjects = projects.where(_matchesFilters).toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: SafeArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    pageGutter,
                    12,
                    pageGutter,
                    AppTheme.pageGutter +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Projects',
                            style: textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: _searchVisible
                              ? 'Close project search'
                              : 'Search projects',
                          onPressed: () {
                            setState(() {
                              _searchVisible = !_searchVisible;
                              if (!_searchVisible) {
                                _searchController.clear();
                                _query = '';
                              }
                            });
                          },
                          icon: Icon(
                            _searchVisible ? Icons.close : Icons.search,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Showcase your work, skills, and the impact you made.',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _addProject,
                        icon: const Icon(Icons.add),
                        label: const Text('Add project'),
                      ),
                    ),
                    if (_searchVisible) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('projectSearchField'),
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search projects',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _publicationChip('All', null),
                        _publicationChip(
                          'Published',
                          ProjectPublicationStatus.published,
                        ),
                        _publicationChip(
                          'Draft',
                          ProjectPublicationStatus.draft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredProjects.isEmpty)
                      _NoProjectMatches(
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _publicationFilter = null;
                          });
                        },
                      )
                    else
                      for (final project in filteredProjects)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectListTile(
                            project: project,
                            onTap: () => _openProject(project),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _publicationChip(String label, ProjectPublicationStatus? value) =>
      ChoiceChip(
        key: Key('projectPublicationFilter-${value?.name ?? 'all'}'),
        label: Text(label),
        selected: _publicationFilter == value,
        onSelected: (_) => setState(() => _publicationFilter = value),
      );

  bool _matchesFilters(Project project) {
    if (_publicationFilter != null &&
        project.publicationStatus != _publicationFilter) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      project.title,
      project.summary,
      project.problemStatement,
      project.description,
      project.contribution,
      project.challenges,
      project.lessonsLearned,
      project.repositoryUrl,
      project.demoUrl,
      ...project.technologies,
      project.status.name,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

class _EmptyProjectsState extends StatelessWidget {
  const _EmptyProjectsState({required this.onAddProject});

  final VoidCallback onAddProject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          28,
          28,
          28,
          AppTheme.pageGutter + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIconTile(
                icon: Icons.folder_open_outlined,
                size: 58,
                iconSize: 28,
              ),
              const SizedBox(height: 20),
              Text('No projects yet', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Start with real work you can explain. Add what you made, your contribution, and the technologies you used.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAddProject,
                icon: const Icon(Icons.add),
                label: const Text('Add your first project'),
              ),
              const SizedBox(height: 12),
              Text(
                'Projects are private drafts until you choose what to share.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectLoadError extends StatelessWidget {
  const _ProjectLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconTile(
              icon: Icons.cloud_off_outlined,
              size: 54,
              iconSize: 25,
            ),
            const SizedBox(height: 16),
            Text(
              'Projects could not be loaded',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check that the projects migration has been run in your Supabase project, then try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
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
}

class _NoProjectMatches extends StatelessWidget {
  const _NoProjectMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Text(
            'No projects match these filters',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or clear the filters.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    ),
  );
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconTile(
                    icon: Icons.work_outline,
                    color: AppColors.indigo,
                    backgroundColor: AppColors.indigoContainer,
                    size: 44,
                    iconSize: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PublicationLabel(status: project.publicationStatus),
                ],
              ),
              if (project.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(project.summary, style: theme.textTheme.bodyMedium),
              ],
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: project.technologies.take(4).map((technology) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(technology),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    project.status == ProjectStatus.completed
                        ? Icons.check_circle_outline
                        : Icons.timelapse_outlined,
                    size: 16,
                    color: AppColors.slateGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusText(project.status),
                    style: theme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.slateGray,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicationLabel extends StatelessWidget {
  const _PublicationLabel({required this.status});

  final ProjectPublicationStatus status;

  @override
  Widget build(BuildContext context) {
    final published = status == ProjectPublicationStatus.published;
    final label = published ? 'Published' : 'Draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: published ? AppColors.tealContainer : AppColors.indigoContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: published ? AppColors.teal : AppColors.indigo,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _statusText(ProjectStatus status) => switch (status) {
  ProjectStatus.inProgress => 'In progress',
  ProjectStatus.completed => 'Completed',
  ProjectStatus.paused => 'Paused',
};
