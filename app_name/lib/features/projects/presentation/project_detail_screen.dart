import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.repository,
  });

  final Project project;
  final ProjectRepository repository;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project = widget.project;
  bool _deleting = false;

  Future<void> _editProject() async {
    final updated = await Navigator.of(context).push<Project>(
      MaterialPageRoute(
        builder: (_) =>
            ProjectFormScreen(repository: widget.repository, project: _project),
      ),
    );
    if (updated != null && mounted) setState(() => _project = updated);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this project?'),
        content: const Text(
          'This removes the project from your account. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep project'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete project'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.repository.deleteProject(_project.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Project could not be deleted. Check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project details'),
        actions: [
          IconButton(
            tooltip: 'Edit project',
            onPressed: _deleting ? null : _editProject,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete project',
            onPressed: _deleting ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(pageGutter, 8, pageGutter, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconTile(
                    icon: Icons.work_outline,
                    size: 52,
                    iconSize: 25,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _project.title,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DetailBadge(label: _statusLabel(_project.status)),
                  const _DetailBadge(label: 'Private draft'),
                ],
              ),
              if (_project.summary.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(_project.summary, style: theme.textTheme.titleMedium),
              ],
              if (_project.technologies.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Technologies', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _project.technologies
                      .map((technology) => Chip(label: Text(technology)))
                      .toList(),
                ),
              ],
              _section(context, 'Problem or need', _project.problemStatement),
              _section(context, 'Project description', _project.description),
              if (_project.keyFeatures.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Key features', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final feature in _project.keyFeatures)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7, right: 10),
                          child: Icon(Icons.circle, size: 7),
                        ),
                        Expanded(
                          child: Text(
                            feature,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              _section(context, 'Your contribution', _project.contribution),
              _section(context, 'Challenges', _project.challenges),
              _section(context, 'Lessons learned', _project.lessonsLearned),
              if (_project.startDate != null || _project.endDate != null) ...[
                const SizedBox(height: 20),
                Text('Timeline', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  '${_date(_project.startDate)} – ${_date(_project.endDate)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              _section(context, 'Repository', _project.repositoryUrl),
              _section(context, 'Live demo', _project.demoUrl),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This project is private. Add supporting links and files from your Evidence library.',
                        style: theme.textTheme.bodyMedium,
                      ),
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

  Widget _section(BuildContext context, String title, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

String _statusLabel(ProjectStatus status) => switch (status) {
  ProjectStatus.inProgress => 'In progress',
  ProjectStatus.completed => 'Completed',
  ProjectStatus.paused => 'Paused',
};

String _date(DateTime? date) {
  if (date == null) return 'Not set';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
