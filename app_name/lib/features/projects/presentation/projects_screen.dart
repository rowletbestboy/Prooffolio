import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../../core/widgets/app_icon_tile.dart';
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

  @override
  void initState() {
    super.initState();
    _projectsFuture = widget.repository.listProjects();
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
      floatingActionButton: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.data?.isNotEmpty != true) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addProject,
            icon: const Icon(Icons.add),
            label: const Text('Add project'),
          );
        },
      ),
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
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(pageGutter, 8, pageGutter, 96),
                children: [
                  Text(
                    'A record of what you made and what you contributed.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  for (final project in projects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProjectListTile(
                        project: project,
                        onTap: () => _openProject(project),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
        padding: const EdgeInsets.all(28),
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
                    size: 44,
                    iconSize: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusLabel(status: project.status),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'Private draft · Open project',
                    style: theme.textTheme.labelMedium,
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

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      ProjectStatus.inProgress => 'In progress',
      ProjectStatus.completed => 'Completed',
      ProjectStatus.paused => 'Paused',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
