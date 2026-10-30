import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../data/project_repository.dart';
import '../domain/project.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, required this.repository, this.project});

  final ProjectRepository repository;
  final Project? project;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(
    text: widget.project?.title ?? '',
  );
  late final TextEditingController _summary = TextEditingController(
    text: widget.project?.summary ?? '',
  );
  late final TextEditingController _problem = TextEditingController(
    text: widget.project?.problemStatement ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.project?.description ?? '',
  );
  late final TextEditingController _features = TextEditingController(
    text: widget.project?.keyFeatures.join('\n') ?? '',
  );
  late final TextEditingController _technologies = TextEditingController(
    text: widget.project?.technologies.join(', ') ?? '',
  );
  late final TextEditingController _contribution = TextEditingController(
    text: widget.project?.contribution ?? '',
  );
  late final TextEditingController _challenges = TextEditingController(
    text: widget.project?.challenges ?? '',
  );
  late final TextEditingController _lessons = TextEditingController(
    text: widget.project?.lessonsLearned ?? '',
  );
  late final TextEditingController _repositoryUrl = TextEditingController(
    text: widget.project?.repositoryUrl ?? '',
  );
  late final TextEditingController _demoUrl = TextEditingController(
    text: widget.project?.demoUrl ?? '',
  );

  ProjectStatus _status = ProjectStatus.inProgress;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  String? _error;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _status = widget.project?.status ?? ProjectStatus.inProgress;
    _startDate = widget.project?.startDate;
    _endDate = widget.project?.endDate;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _summary,
      _problem,
      _description,
      _features,
      _technologies,
      _contribution,
      _challenges,
      _lessons,
      _repositoryUrl,
      _demoUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(
        () => _dateError = 'End date must be on or after the start date.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _dateError = null;
    });
    final draft = ProjectDraft(
      title: _title.text,
      summary: _summary.text,
      problemStatement: _problem.text,
      description: _description.text,
      keyFeatures: _splitLines(_features.text),
      technologies: _splitTechnologies(_technologies.text),
      contribution: _contribution.text,
      challenges: _challenges.text,
      lessonsLearned: _lessons.text,
      repositoryUrl: _repositoryUrl.text,
      demoUrl: _demoUrl.text,
      publicationStatus:
          widget.project?.publicationStatus ?? ProjectPublicationStatus.draft,
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
    );
    try {
      final saved = widget.project == null
          ? await widget.repository.createProject(draft)
          : await widget.repository.updateProject(widget.project!.id, draft);
      if (mounted) Navigator.of(context).pop(saved);
    } on PostgrestException catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Could not save project (Supabase error ${error.code ?? 'unknown'}). Check the projects migration and try again.';
        });
      }
    } on AuthException {
      if (mounted) {
        setState(() => _error = 'Your session expired. Sign in again.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your project. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    final theme = Theme.of(context);
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppPageAppBar(title: isEditing ? 'Edit project' : 'New project'),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? 'Saving…'
                : isEditing
                ? 'Save changes'
                : 'Save draft',
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pageGutter, 8, pageGutter, 32),
              children: [
                Text(
                  'Start with the details you know. You can add evidence and skills later.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                _sectionLabel(context, 'Overview'),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('projectTitleField'),
                  controller: _title,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Project title *',
                  ),
                  validator: (value) => value?.trim().isNotEmpty == true
                      ? null
                      : 'Enter a project title',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('projectSummaryField'),
                  controller: _summary,
                  maxLength: 280,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Short summary',
                    helperText: 'A concise description for your project list',
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'What you made'),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Problem or need',
                  controller: _problem,
                  maxLength: 5000,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Project description',
                  controller: _description,
                  maxLength: 8000,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Key features',
                  controller: _features,
                  maxLength: 3000,
                  maxLines: 3,
                  helperText: 'One feature per line',
                ),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Technologies used',
                  controller: _technologies,
                  maxLength: 1000,
                  maxLines: 2,
                  helperText: 'Separate technologies with commas',
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Your contribution'),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'What you did',
                  controller: _contribution,
                  maxLength: 3000,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Challenges',
                  controller: _challenges,
                  maxLength: 3000,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _narrativeField(
                  label: 'Lessons learned',
                  controller: _lessons,
                  maxLength: 3000,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _sectionLabel(context, 'Timeline and links'),
                const SizedBox(height: 12),
                _DatePickerField(
                  key: const Key('projectStartDateField'),
                  label: 'Start date',
                  date: _startDate,
                  onTap: () => _pickDate(start: true),
                  onClear: () => setState(() => _startDate = null),
                ),
                const SizedBox(height: 12),
                _DatePickerField(
                  key: const Key('projectEndDateField'),
                  label: 'End date',
                  date: _endDate,
                  onTap: () => _pickDate(start: false),
                  onClear: () => setState(() => _endDate = null),
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _dateError!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Project status',
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('projectRepositoryUrlField'),
                  controller: _repositoryUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Repository URL',
                    hintText: 'https://github.com/…',
                  ),
                  validator: _validateOptionalUrl,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('projectDemoUrlField'),
                  controller: _demoUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Live demo URL',
                    hintText: 'https://…',
                  ),
                  validator: _validateOptionalUrl,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  ),
                  child: Text(
                    'This project is saved as a private draft. You can choose what to share later.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _narrativeField({
    required String label,
    required TextEditingController controller,
    required int maxLength,
    required int maxLines,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, helperText: helperText),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final icon = switch (label) {
      'Overview' => Icons.title_outlined,
      'What you made' => Icons.lightbulb_outline,
      'Your contribution' => Icons.handyman_outlined,
      _ => Icons.calendar_month_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          AppIconTile(icon: icon, size: 36, iconSize: 18),
          const SizedBox(width: 10),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  String? _validateOptionalUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      return 'Enter a valid http or https URL';
    }
    return null;
  }

  String _statusLabel(ProjectStatus status) => switch (status) {
    ProjectStatus.inProgress => 'In progress',
    ProjectStatus.completed => 'Completed',
    ProjectStatus.paused => 'Paused',
  };
}

List<String> _splitLines(String value) => value
    .split(RegExp(r'[\r\n]+'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

List<String> _splitTechnologies(String value) => value
    .split(RegExp(r'[,\r\n]+'))
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

String _formatDate(DateTime? date) {
  if (date == null) return 'Choose date';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_formatDate(date)),
              ),
            ),
          ),
          if (date != null)
            IconButton(
              tooltip: 'Clear $label',
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
            ),
          IconButton(
            tooltip: 'Choose $label',
            visualDensity: VisualDensity.compact,
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}
