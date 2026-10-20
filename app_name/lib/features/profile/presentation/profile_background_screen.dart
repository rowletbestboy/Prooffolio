import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../domain/profile.dart';

class ProfileBackgroundScreen extends StatefulWidget {
  const ProfileBackgroundScreen({
    super.key,
    required this.repository,
    required this.userId,
  });

  final ProfileBackgroundRepository repository;
  final String userId;

  @override
  State<ProfileBackgroundScreen> createState() =>
      _ProfileBackgroundScreenState();
}

class _ProfileBackgroundScreenState extends State<ProfileBackgroundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _occupationTitle = TextEditingController();
  final _interests = TextEditingController();
  final _targetRoles = TextEditingController();
  final _occupationSearch = TextEditingController();
  late Future<_ProfileData> _dataFuture;
  late ProfileBackground _profile;
  List<EducationRecord> _education = [];
  List<ExperienceRecord> _experience = [];
  OccupationCategory? _occupationCategory;
  CareerStage? _careerStage;
  bool _populated = false;
  bool _listsPopulated = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _occupationTitle.dispose();
    _interests.dispose();
    _targetRoles.dispose();
    _occupationSearch.dispose();
    super.dispose();
  }

  Future<_ProfileData> _loadData() async => _ProfileData(
    profile: await widget.repository.loadProfile(widget.userId),
    education: await widget.repository.listEducation(widget.userId),
    experience: await widget.repository.listExperience(widget.userId),
  );

  void _populate(ProfileBackground profile) {
    if (_populated) return;
    _profile = profile;
    _headline.text = profile.headline;
    _bio.text = profile.bio;
    _occupationTitle.text = profile.occupationTitle;
    _interests.text = profile.interests.join(', ');
    _targetRoles.text = profile.targetRoles.join(', ');
    _occupationCategory = profile.occupationCategory;
    _careerStage = profile.careerStage;
    _populated = true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = ProfileBackground(
        displayName: _profile.displayName,
        username: _profile.username,
        headline: _headline.text,
        bio: _bio.text,
        occupationCategory: _occupationCategory,
        occupationTitle: _occupationTitle.text,
        careerStage: _careerStage,
        interests: _splitList(_interests.text),
        targetRoles: _splitList(_targetRoles.text),
      );
      await widget.repository.saveBackground(widget.userId, updated);
      _profile = updated;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Profile could not be saved. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addEducation([EducationRecord? record]) async {
    final draft = await showDialog<EducationDraft>(
      context: context,
      builder: (_) => _EducationEditor(initial: record),
    );
    if (draft == null) return;
    try {
      final saved = await widget.repository.saveEducation(
        widget.userId,
        draft,
        id: record?.id,
      );
      if (!mounted) return;
      setState(() {
        _education = [
          saved,
          ..._education.where((item) => item.id != saved.id),
        ];
      });
    } catch (_) {
      _showError(
        'Education could not be saved. Check the details and try again.',
      );
    }
  }

  Future<void> _addExperience([ExperienceRecord? record]) async {
    final draft = await showDialog<ExperienceDraft>(
      context: context,
      builder: (_) => _ExperienceEditor(initial: record),
    );
    if (draft == null) return;
    try {
      final saved = await widget.repository.saveExperience(
        widget.userId,
        draft,
        id: record?.id,
      );
      if (!mounted) return;
      setState(() {
        _experience = [
          saved,
          ..._experience.where((item) => item.id != saved.id),
        ];
      });
    } catch (_) {
      _showError(
        'Experience could not be saved. Check the details and try again.',
      );
    }
  }

  Future<void> _deleteEducation(EducationRecord record) async {
    if (!await _confirmDelete('Delete this education record?')) return;
    try {
      await widget.repository.deleteEducation(widget.userId, record.id);
      if (mounted) {
        setState(() => _education.removeWhere((item) => item.id == record.id));
      }
    } catch (_) {
      _showError('Education record could not be deleted. Try again.');
    }
  }

  Future<void> _deleteExperience(ExperienceRecord record) async {
    if (!await _confirmDelete('Delete this experience record?')) return;
    try {
      await widget.repository.deleteExperience(widget.userId, record.id);
      if (mounted) {
        setState(() => _experience.removeWhere((item) => item.id == record.id));
      }
    } catch (_) {
      _showError('Experience record could not be deleted. Try again.');
    }
  }

  Future<bool> _confirmDelete(String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile and background')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: _saving ? null : _saveProfile,
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile'),
        ),
      ),
      body: FutureBuilder<_ProfileData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ProfileLoadError(
              onRetry: () {
                setState(() => _dataFuture = _loadData());
              },
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data.profile == null) {
            return const Center(
              child: Text('Your profile could not be found.'),
            );
          }
          _populate(data.profile!);
          if (!_listsPopulated) {
            _education = data.education;
            _experience = data.experience;
            _listsPopulated = true;
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      'A fuller picture of your work',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell people what you do, what you are learning, and the experience you want them to see. Every field here is optional.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    _sectionHeading(context, 'About you'),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileHeadlineField'),
                      controller: _headline,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Professional headline (optional)',
                        hintText: 'For example, Community health educator',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileBioField'),
                      controller: _bio,
                      maxLength: 2000,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'About your work (optional)',
                        hintText: 'What matters in the work you do?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _occupationPicker(),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('occupationTitleField'),
                      controller: _occupationTitle,
                      maxLength: 120,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Role or occupation (optional)',
                        hintText: 'Add your own title or specialty',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CareerStage?>(
                      key: const Key('careerStageField'),
                      initialValue: _careerStage,
                      decoration: const InputDecoration(
                        labelText: 'Where you are in your career (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<CareerStage?>(
                          value: null,
                          child: Text('Choose a stage'),
                        ),
                        for (final stage in CareerStage.values)
                          DropdownMenuItem<CareerStage?>(
                            value: stage,
                            child: Text(stage.label),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _careerStage = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileInterestsField'),
                      controller: _interests,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Areas of interest (optional)',
                        helperText: 'Separate items with commas',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('profileTargetRolesField'),
                      controller: _targetRoles,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Roles you are interested in (optional)',
                        helperText: 'Separate items with commas',
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeading(context, 'Education and training'),
                    const SizedBox(height: 6),
                    Text(
                      'Include a course in progress, a completed qualification, or any learning you want to share.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (_education.isEmpty)
                      const _NoRecords(label: 'No education added')
                    else
                      for (final record in _education)
                        _BackgroundRecordTile(
                          title: record.title,
                          subtitle: [
                            if (record.institution.isNotEmpty)
                              record.institution,
                            record.status.label,
                          ].join(' · '),
                          onTap: () => _addEducation(record),
                          onDelete: () => _deleteEducation(record),
                          deleteTooltip: 'Delete education record',
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addEducation(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add education'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionHeading(context, 'Experience'),
                    const SizedBox(height: 6),
                    Text(
                      'Paid work is only one kind of experience. You can include freelance, volunteer, community, caregiving, or independent work.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    if (_experience.isEmpty)
                      const _NoRecords(label: 'No experience added')
                    else
                      for (final record in _experience)
                        _BackgroundRecordTile(
                          title: record.title,
                          subtitle: [
                            record.type.label,
                            if (record.organization?.isNotEmpty == true)
                              record.organization!,
                            if (record.isCurrent) 'Current',
                          ].join(' · '),
                          onTap: () => _addExperience(record),
                          onDelete: () => _deleteExperience(record),
                          deleteTooltip: 'Delete experience record',
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _addExperience(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add experience'),
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
          );
        },
      ),
    );
  }

  Future<void> _chooseOccupationCategory() async {
    _occupationSearch.clear();
    final selected = await showModalBottomSheet<OccupationCategory>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final query = _occupationSearch.text.trim().toLowerCase();
          final categories = OccupationCategory.values.where(
            (category) => category.label.toLowerCase().contains(query),
          );
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * .7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a field of work',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('occupationSearchField'),
                      controller: _occupationSearch,
                      autofocus: true,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search fields',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final category in categories)
                            ListTile(
                              title: Text(category.label),
                              onTap: () =>
                                  Navigator.pop(sheetContext, category),
                            ),
                        ],
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
    if (selected != null && mounted) {
      setState(() => _occupationCategory = selected);
    }
  }

  Widget _occupationPicker() => InkWell(
    key: const Key('occupationCategoryField'),
    onTap: _chooseOccupationCategory,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Field of work (optional)',
        suffixIcon: Icon(Icons.search),
      ),
      child: Text(
        _occupationCategory?.label ?? 'Search or choose a field',
        style: _occupationCategory == null
            ? TextStyle(color: Theme.of(context).hintColor)
            : null,
      ),
    ),
  );

  Widget _sectionHeading(BuildContext context, String title) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _ProfileData {
  const _ProfileData({
    required this.profile,
    required this.education,
    required this.experience,
  });
  final ProfileBackground? profile;
  final List<EducationRecord> education;
  final List<ExperienceRecord> experience;
}

class _NoRecords extends StatelessWidget {
  const _NoRecords({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _BackgroundRecordTile extends StatelessWidget {
  const _BackgroundRecordTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
    required this.deleteTooltip,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String deleteTooltip;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        tooltip: deleteTooltip,
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Profile details could not be loaded',
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

class _EducationEditor extends StatefulWidget {
  const _EducationEditor({this.initial});
  final EducationRecord? initial;

  @override
  State<_EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends State<_EducationEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _institution = TextEditingController(
    text: widget.initial?.institution ?? '',
  );
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late EducationLevel? _level = widget.initial?.level;
  late EducationStatus _status =
      widget.initial?.status ?? EducationStatus.inProgress;
  late DateTime? _startDate = widget.initial?.startDate;
  late DateTime? _endDate = widget.initial?.endDate;

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _institution.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add education' : 'Edit education'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('educationTitleField'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Course or qualification',
              ),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Enter a course or qualification',
            ),
            TextFormField(
              key: const Key('educationInstitutionField'),
              controller: _institution,
              decoration: const InputDecoration(
                labelText: 'School or provider (optional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EducationLevel?>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level (optional)'),
              items: [
                const DropdownMenuItem<EducationLevel?>(
                  value: null,
                  child: Text('Choose a level'),
                ),
                for (final level in EducationLevel.values)
                  DropdownMenuItem<EducationLevel?>(
                    value: level,
                    child: Text(level.label),
                  ),
              ],
              onChanged: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EducationStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Progress'),
              items: [
                for (final status in EducationStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            Row(
              children: [
                Expanded(
                  child: _OptionalDateButton(
                    label: 'Start date',
                    value: _startDate,
                    onPressed: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OptionalDateButton(
                    label: 'End date',
                    value: _endDate,
                    onPressed: () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            EducationDraft(
              title: _title.text,
              institution: _institution.text,
              level: _level,
              status: _status,
              startDate: _startDate,
              endDate: _endDate,
              description: _description.text,
            ),
          );
        },
        child: const Text('Save education'),
      ),
    ],
  );
}

class _ExperienceEditor extends StatefulWidget {
  const _ExperienceEditor({this.initial});
  final ExperienceRecord? initial;

  @override
  State<_ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends State<_ExperienceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _organization = TextEditingController(
    text: widget.initial?.organization ?? '',
  );
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late ExperienceType _type = widget.initial?.type ?? ExperienceType.employment;
  late bool _isCurrent = widget.initial?.isCurrent ?? false;
  late DateTime? _startDate = widget.initial?.startDate;
  late DateTime? _endDate = widget.initial?.endDate;

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _organization.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add experience' : 'Edit experience'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('experienceTitleField'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Role or experience',
              ),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Enter a role or experience',
            ),
            TextFormField(
              controller: _organization,
              decoration: const InputDecoration(
                labelText: 'Organization (optional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExperienceType>(
              key: const Key('experienceTypeField'),
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type of experience',
              ),
              items: [
                for (final type in ExperienceType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            CheckboxListTile(
              key: const Key('experienceCurrentField'),
              contentPadding: EdgeInsets.zero,
              value: _isCurrent,
              title: const Text('I do this currently'),
              onChanged: (value) => setState(() => _isCurrent = value ?? false),
            ),
            Row(
              children: [
                Expanded(
                  child: _OptionalDateButton(
                    label: 'Start date',
                    value: _startDate,
                    onPressed: () => _pickDate(start: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OptionalDateButton(
                    label: 'End date',
                    value: _endDate,
                    onPressed: _isCurrent
                        ? null
                        : () => _pickDate(start: false),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What you did (optional)',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            ExperienceDraft(
              title: _title.text,
              organization: _organization.text.trim().isEmpty
                  ? null
                  : _organization.text.trim(),
              type: _type,
              startDate: _startDate,
              endDate: _isCurrent ? null : _endDate,
              isCurrent: _isCurrent,
              description: _description.text,
            ),
          );
        },
        child: const Text('Save experience'),
      ),
    ],
  );
}

class _OptionalDateButton extends StatelessWidget {
  const _OptionalDateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });
  final String label;
  final DateTime? value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.calendar_today_outlined, size: 16),
    label: Text(
      value == null
          ? label
          : '${value!.year}-${value!.month.toString().padLeft(2, '0')}',
    ),
  );
}

List<String> _splitList(String text) => text
    .split(',')
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);
