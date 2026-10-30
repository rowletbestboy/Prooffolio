import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import '../data/portfolio_record_repository.dart';
import '../domain/portfolio_record.dart';

class PortfolioRecordsScreen extends StatefulWidget {
  const PortfolioRecordsScreen({
    super.key,
    required this.repository,
    this.initialType = PortfolioRecordType.certification,
  });

  final PortfolioRecordRepository repository;
  final PortfolioRecordType initialType;

  @override
  State<PortfolioRecordsScreen> createState() => _PortfolioRecordsScreenState();
}

class _PortfolioRecordsScreenState extends State<PortfolioRecordsScreen> {
  late PortfolioRecordType _type;
  List<PortfolioRecord> _records = [];
  bool _loading = true;
  Object? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final requestedType = _type;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final records = await widget.repository.listRecords(requestedType);
      if (mounted && requestedType == _type) {
        setState(() => _records = records);
      }
    } catch (error) {
      if (mounted && requestedType == _type) {
        setState(() => _loadError = error);
      }
    } finally {
      if (mounted && requestedType == _type) setState(() => _loading = false);
    }
  }

  void _selectType(PortfolioRecordType type) {
    if (_type == type) return;
    setState(() => _type = type);
    _loadRecords();
  }

  Future<void> _editRecord([PortfolioRecord? record]) async {
    if (_saving) return;
    final draft = await showDialog<PortfolioRecordDraft>(
      context: context,
      builder: (_) =>
          _PortfolioRecordEditor(recordType: _type, initial: record),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (record == null) {
        await widget.repository.createRecord(draft);
      } else {
        await widget.repository.updateRecord(record.id, draft);
      }
      if (mounted) {
        await _loadRecords();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${_type.singularLabel} saved')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_type.singularLabel} could not be saved. Try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteRecord(PortfolioRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_type.singularLabel.toLowerCase()}?'),
        content: const Text('This record will be removed from your account.'),
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
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteRecord(record.id);
      if (mounted) await _loadRecords();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record could not be deleted. Try again.'),
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
      appBar: const AppPageAppBar(title: 'Certifications and achievements'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _editRecord(),
        icon: const Icon(Icons.add),
        label: Text('Add ${_type.singularLabel.toLowerCase()}'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(pageGutter, 12, pageGutter, 104),
            children: [
              Text(
                'Recognition and learning',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Keep track of credentials, milestones, and recognition that matter to your work. You can add these without a project.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              SegmentedButton<PortfolioRecordType>(
                showSelectedIcon: false,
                segments: [
                  for (final type in PortfolioRecordType.values)
                    ButtonSegment(value: type, label: Text(type.label)),
                ],
                selected: {_type},
                onSelectionChanged: (selection) => _selectType(selection.first),
              ),
              const SizedBox(height: 16),
              if (_loadError != null)
                _PortfolioRecordsError(onRetry: _loadRecords)
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_records.isEmpty)
                _PortfolioRecordsEmpty(type: _type, onAdd: () => _editRecord())
              else
                for (final record in _records)
                  _PortfolioRecordTile(
                    record: record,
                    onTap: () => _editRecord(record),
                    onDelete: () => _deleteRecord(record),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on PortfolioRecordType {
  String get singularLabel => switch (this) {
    PortfolioRecordType.certification => 'Certification',
    PortfolioRecordType.achievement => 'Achievement',
  };
}

class _PortfolioRecordsEmpty extends StatelessWidget {
  const _PortfolioRecordsEmpty({required this.type, required this.onAdd});

  final PortfolioRecordType type;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final kind = type.singularLabel.toLowerCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 24),
      child: Column(
        children: [
          AppIconTile(
            icon: type == PortfolioRecordType.certification
                ? Icons.workspace_premium_outlined
                : Icons.emoji_events_outlined,
            color: type == PortfolioRecordType.certification
                ? AppColors.indigo
                : AppColors.amber,
            backgroundColor: type == PortfolioRecordType.certification
                ? AppColors.indigoContainer
                : AppColors.amberContainer,
            size: 58,
            iconSize: 28,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${type.label.toLowerCase()} yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a $kind whenever you are ready. A project is not required.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('Add $kind'),
          ),
        ],
      ),
    );
  }
}

class _PortfolioRecordTile extends StatelessWidget {
  const _PortfolioRecordTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final PortfolioRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (record.source.isNotEmpty) record.source,
      if (record.achievedOn != null) _formatDate(record.achievedOn!),
      if (record.expiresOn != null) 'Expires ${_formatDate(record.expiresOn!)}',
      'Private',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: AppIconTile(
          icon: record.recordType == PortfolioRecordType.certification
              ? Icons.workspace_premium_outlined
              : Icons.emoji_events_outlined,
          color: record.recordType == PortfolioRecordType.certification
              ? AppColors.indigo
              : AppColors.amber,
          backgroundColor:
              record.recordType == PortfolioRecordType.certification
              ? AppColors.indigoContainer
              : AppColors.amberContainer,
          size: 44,
          iconSize: 21,
        ),
        title: Text(record.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(details.join(' · ')),
              if (record.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  record.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete record',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _PortfolioRecordsError extends StatelessWidget {
  const _PortfolioRecordsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Text(
          'Records could not be loaded. Check your connection and try again.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

class _PortfolioRecordEditor extends StatefulWidget {
  const _PortfolioRecordEditor({required this.recordType, this.initial});

  final PortfolioRecordType recordType;
  final PortfolioRecord? initial;

  @override
  State<_PortfolioRecordEditor> createState() => _PortfolioRecordEditorState();
}

class _PortfolioRecordEditorState extends State<_PortfolioRecordEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _source = TextEditingController(
    text: widget.initial?.source ?? '',
  );
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final _achievedOn = TextEditingController(
    text: _formatInputDate(widget.initial?.achievedOn),
  );
  late final _expiresOn = TextEditingController(
    text: _formatInputDate(widget.initial?.expiresOn),
  );

  @override
  void dispose() {
    _title.dispose();
    _source.dispose();
    _description.dispose();
    _achievedOn.dispose();
    _expiresOn.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (date != null) controller.text = _formatInputDate(date);
  }

  DateTime? _parseOptionalDate(String value) {
    if (value.trim().isEmpty) return null;
    final text = value.trim();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    if (text.length == 10) {
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    }
    return parsed.toUtc();
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim()) == null ? 'Use YYYY-MM-DD' : null;
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.recordType.singularLabel.toLowerCase();
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add $kind' : 'Edit $kind'),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('portfolioRecordTitleField'),
                  controller: _title,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value?.trim().isNotEmpty == true ? null : 'Enter a name',
                ),
                TextFormField(
                  key: const Key('portfolioRecordSourceField'),
                  controller: _source,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Issuer or source (optional)',
                  ),
                ),
                TextFormField(
                  key: const Key('portfolioRecordAchievedOnField'),
                  controller: _achievedOn,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    labelText: 'Date (optional)',
                    hintText: 'YYYY-MM-DD',
                    suffixIcon: IconButton(
                      tooltip: 'Choose date',
                      onPressed: () => _pickDate(_achievedOn),
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: _validateDate,
                ),
                if (widget.recordType == PortfolioRecordType.certification)
                  TextFormField(
                    key: const Key('portfolioRecordExpiresOnField'),
                    controller: _expiresOn,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Expiration date (optional)',
                      hintText: 'YYYY-MM-DD',
                      suffixIcon: IconButton(
                        tooltip: 'Choose expiration date',
                        onPressed: () => _pickDate(_expiresOn),
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    validator: (value) {
                      final invalid = _validateDate(value);
                      if (invalid != null) return invalid;
                      final earned = _parseOptionalDate(_achievedOn.text);
                      final expires = _parseOptionalDate(value ?? '');
                      if (earned != null &&
                          expires != null &&
                          expires.isBefore(earned)) {
                        return 'Expiration must be after the date';
                      }
                      return null;
                    },
                  ),
                TextFormField(
                  key: const Key('portfolioRecordDescriptionField'),
                  controller: _description,
                  maxLength: 3000,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Private to you'),
                ),
              ],
            ),
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
            final draft = PortfolioRecordDraft(
              recordType: widget.recordType,
              title: _title.text,
              source: _source.text,
              description: _description.text,
              achievedOn: _parseOptionalDate(_achievedOn.text),
              expiresOn: widget.recordType == PortfolioRecordType.certification
                  ? _parseOptionalDate(_expiresOn.text)
                  : null,
              isPublic: false,
            );
            Navigator.pop(context, draft);
          },
          child: Text('Save $kind'),
        ),
      ],
    );
  }
}

String _formatInputDate(DateTime? date) {
  if (date == null) return '';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
