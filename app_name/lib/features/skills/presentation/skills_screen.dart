import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/domain/project.dart';
import '../data/skill_repository.dart';
import '../domain/skill.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({
    super.key,
    required this.repository,
    this.projectRepository,
  });

  final SkillRepository repository;
  final ProjectRepository? projectRepository;

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late Future<List<Skill>> _skillsFuture;
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  String _query = '';
  SkillCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _skillsFuture = widget.repository.listSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _skillsFuture = widget.repository.listSkills();
  });

  Future<void> _editSkill([Skill? skill]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _SkillFormScreen(
          repository: widget.repository,
          projectRepository: widget.projectRepository,
          skill: skill,
        ),
      ),
    );
    if (result == true && mounted) _reload();
  }

  Future<void> _deleteSkill(Skill skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this skill?'),
        content: Text('“${skill.name}” and its project links will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete skill'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteSkill(skill.id);
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Skill could not be deleted. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Skills'),
      body: FutureBuilder<List<Skill>>(
        future: _skillsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _SkillsLoadError(onRetry: _reload);
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final skills = snapshot.data ?? const <Skill>[];
          if (skills.isEmpty) {
            return _EmptySkillsState(onAdd: () => _editSkill());
          }
          final filteredSkills = skills.where(_matchesFilters).toList();
          final linkedSkillCount = skills
              .where((skill) => skill.projectIds.isNotEmpty)
              .length;
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
                            'Skills',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        IconButton(
                          key: const Key('skillSearchToggle'),
                          tooltip: _searchVisible
                              ? 'Close skill search'
                              : 'Search skills',
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
                      'Organize your strengths and where you have used them.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () => _editSkill(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add skill'),
                      ),
                    ),
                    if (_searchVisible) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('skillSearchField'),
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search skills',
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
                    const SizedBox(height: 16),
                    _SkillsSummary(
                      skillCount: skills.length,
                      linkedSkillCount: linkedSkillCount,
                    ),
                    const SizedBox(height: 12),
                    const _SelfReportedNote(),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _categoryChip('All', null),
                          for (final category in SkillCategory.values)
                            _categoryChip(category.label, category),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filteredSkills.isEmpty)
                      _NoSkillMatches(
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _categoryFilter = null;
                          });
                        },
                      )
                    else
                      for (final category in SkillCategory.values)
                        if (filteredSkills.any(
                          (skill) => skill.category == category,
                        )) ...[
                          _SkillCategoryHeading(
                            key: Key('skillCategoryGroup-${category.name}'),
                            category: category,
                            count: filteredSkills
                                .where((skill) => skill.category == category)
                                .length,
                          ),
                          for (final skill in filteredSkills.where(
                            (skill) => skill.category == category,
                          ))
                            _SkillListItem(
                              skill: skill,
                              onTap: () => _editSkill(skill),
                              onDelete: () => _deleteSkill(skill),
                            ),
                        ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryChip(String label, SkillCategory? category) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      key: Key('skillCategoryFilter-${category?.name ?? 'all'}'),
      label: Text(label),
      selected: _categoryFilter == category,
      onSelected: (_) => setState(() => _categoryFilter = category),
    ),
  );

  bool _matchesFilters(Skill skill) {
    if (_categoryFilter != null && skill.category != _categoryFilter) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      skill.name,
      skill.category.label,
      skill.status.label,
      ...skill.projectTitles,
    ].any((value) => value.toLowerCase().contains(query));
  }
}

class _SkillsSummary extends StatelessWidget {
  const _SkillsSummary({
    required this.skillCount,
    required this.linkedSkillCount,
  });

  final int skillCount;
  final int linkedSkillCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlinkedCount = skillCount - linkedSkillCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightSlate),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 4),
              color: AppColors.tealContainer,
            ),
            child: Text(
              '$skillCount ${skillCount == 1 ? 'skill' : 'skills'}',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.deepNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$linkedSkillCount linked to projects',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlinkedCount not linked yet',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillCategoryHeading extends StatelessWidget {
  const _SkillCategoryHeading({
    super.key,
    required this.category,
    required this.count,
  });

  final SkillCategory category;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            category.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(
          '$count ${count == 1 ? 'skill' : 'skills'}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    ),
  );
}

class _NoSkillMatches extends StatelessWidget {
  const _NoSkillMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Text(
            'No skills match these filters',
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

class _EmptySkillsState extends StatelessWidget {
  const _EmptySkillsState({required this.onAdd});
  final VoidCallback onAdd;

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
                icon: Icons.lightbulb_outline,
                color: AppColors.teal,
                backgroundColor: AppColors.tealContainer,
                size: 58,
                iconSize: 28,
              ),
              const SizedBox(height: 20),
              Text('No skills yet', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Add skills you are learning or have used, then connect them to projects that show your work.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add your first skill'),
              ),
              const SizedBox(height: 16),
              Text(
                'Learning states are self-reported; they are not certifications or skill assessments.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelfReportedNote extends StatelessWidget {
  const _SelfReportedNote();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'These learning states are self-reported. They are not certifications or skill assessments.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillListItem extends StatelessWidget {
  const _SkillListItem({
    required this.skill,
    required this.onTap,
    required this.onDelete,
  });
  final Skill skill;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          leading: const AppIconTile(
            icon: Icons.lightbulb_outline,
            color: AppColors.teal,
            backgroundColor: AppColors.tealContainer,
            size: 44,
            iconSize: 21,
          ),
          title: Text(skill.name, style: theme.textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _LabelChip(label: skill.category.label),
                    _LabelChip(label: skill.status.label, isStatus: true),
                  ],
                ),
                if (skill.projectTitles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Used in ${skill.projectTitles.join(', ')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Skill actions',
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete skill')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, this.isStatus = false});
  final String label;
  final bool isStatus;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isStatus
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isStatus ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SkillsLoadError extends StatelessWidget {
  const _SkillsLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconTile(
            icon: Icons.lightbulb_outline,
            color: AppColors.teal,
            backgroundColor: AppColors.tealContainer,
            size: 54,
            iconSize: 26,
          ),
          const SizedBox(height: 16),
          Text(
            'Skills could not be loaded',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Check your connection and try again.'),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _SkillFormScreen extends StatefulWidget {
  const _SkillFormScreen({
    required this.repository,
    required this.projectRepository,
    this.skill,
  });

  final SkillRepository repository;
  final ProjectRepository? projectRepository;
  final Skill? skill;

  @override
  State<_SkillFormScreen> createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends State<_SkillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.skill?.name ?? '');
  late SkillCategory _category =
      widget.skill?.category ?? SkillCategory.technologyDigital;
  late SkillStatus _status = widget.skill?.status ?? SkillStatus.learning;
  late final Set<String> _projectIds = {...?widget.skill?.projectIds};
  late final Future<List<Project>>? _projectsFuture = widget.projectRepository
      ?.listProjects();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveSkill(
        id: widget.skill?.id,
        draft: SkillDraft(
          name: _name.text,
          category: _category,
          status: _status,
        ),
        projectIds: _projectIds.toList(growable: false),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Skill could not be saved. Check the name and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.skill != null;
    final theme = Theme.of(context);
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppPageAppBar(title: editing ? 'Edit skill' : 'Add skill'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pageGutter, 12, pageGutter, 32),
              children: [
                Text(
                  'Describe the skill in your own words.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('skillNameField'),
                  controller: _name,
                  autofocus: !editing,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Skill name',
                    hintText: 'For example, Dart',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a skill name'
                      : null,
                ),
                const SizedBox(height: 12),
                AppSelectField<SkillCategory>(
                  key: const Key('skillCategoryField'),
                  value: _category,
                  label: 'Category',
                  items: [
                    for (final category in SkillCategory.values)
                      DropdownMenuItem<SkillCategory>(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 16),
                AppSelectField<SkillStatus>(
                  key: const Key('skillStatusField'),
                  value: _status,
                  label: 'Your learning state',
                  items: [
                    for (final status in SkillStatus.values)
                      DropdownMenuItem<SkillStatus>(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is your own description of your progress, not a formal assessment.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Text('Projects', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Link work where you have used this skill.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildProjectsPicker(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(editing ? 'Save changes' : 'Save skill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsPicker() {
    if (_projectsFuture == null) {
      return const Text(
        'Projects are not available right now. You can still save this skill.',
      );
    }
    return FutureBuilder<List<Project>>(
      future: _projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Projects could not be loaded. You can still save without links.',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final projects = snapshot.data ?? const <Project>[];
        if (projects.isEmpty) {
          return const Text('Add a project first to link it to this skill.');
        }
        return Column(
          children: [
            for (final project in projects)
              CheckboxListTile(
                key: Key('skillProject-${project.id}'),
                value: _projectIds.contains(project.id),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(project.title),
                subtitle: project.summary.isEmpty
                    ? null
                    : Text(project.summary),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _projectIds.add(project.id);
                  } else {
                    _projectIds.remove(project.id);
                  }
                }),
              ),
          ],
        );
      },
    );
  }
}
