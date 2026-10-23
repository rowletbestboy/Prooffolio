import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
import '../data/evidence_repository.dart';
import '../domain/evidence.dart';

class PickedEvidenceFile {
  const PickedEvidenceFile({
    required this.name,
    required this.mimeType,
    required this.length,
    required this.readBytes,
  });

  final String name;
  final String? mimeType;
  final int length;
  final Future<Uint8List> Function() readBytes;
}

abstract interface class EvidenceFilePicker {
  Future<PickedEvidenceFile?> pickFile();
}

class PlatformEvidenceFilePicker implements EvidenceFilePicker {
  @override
  Future<PickedEvidenceFile?> pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: EvidenceFilePolicy.allowedExtensions,
    );
    if (file == null) return null;
    final length = file.lengthSync() ?? await file.length();
    if (length == null) {
      throw const EvidenceInputException(
        'The selected file size is unavailable.',
      );
    }
    String? mimeType;
    try {
      mimeType = file.xFile.mimeType;
    } on UnimplementedError {
      mimeType = null;
    }
    return PickedEvidenceFile(
      name: file.name,
      mimeType: mimeType,
      length: length,
      readBytes: file.readAsBytes,
    );
  }
}

class EvidenceLibraryScreen extends StatefulWidget {
  const EvidenceLibraryScreen({
    super.key,
    required this.repository,
    required this.filePicker,
  });

  final EvidenceRepository repository;
  final EvidenceFilePicker filePicker;

  @override
  State<EvidenceLibraryScreen> createState() => _EvidenceLibraryScreenState();
}

class _EvidenceLibraryScreenState extends State<EvidenceLibraryScreen> {
  late Future<_EvidenceData> _dataFuture;
  List<EvidenceRecord> _records = [];
  List<EvidenceTarget> _targets = [];
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_EvidenceData> _loadData() async {
    final values = await Future.wait([
      widget.repository.listEvidence(),
      widget.repository.listTargets(),
    ]);
    return _EvidenceData(
      values[0] as List<EvidenceRecord>,
      values[1] as List<EvidenceTarget>,
    );
  }

  Future<void> _addEvidence() async {
    final submission = await showDialog<_EvidenceSubmission>(
      context: context,
      builder: (_) =>
          _EvidenceEditor(targets: _targets, filePicker: widget.filePicker),
    );
    if (submission == null) return;
    setState(() => _saving = true);
    try {
      final record = submission.kind == EvidenceKind.url
          ? await widget.repository.addUrl(
              title: submission.title,
              sourceUrl: submission.sourceUrl!,
              description: submission.description,
              targets: submission.targets,
            )
          : await widget.repository.uploadFile(
              title: submission.title,
              fileName: submission.file!.name,
              mimeType: submission.file!.mimeType,
              bytes: await submission.file!.readBytes(),
              description: submission.description,
              targets: submission.targets,
            );
      if (!mounted) return;
      setState(() => _records = [record, ..._records]);
      _showMessage('Evidence added');
    } catch (error) {
      if (mounted) {
        _showError(
          error is EvidenceInputException
              ? error.message
              : error is EvidenceCleanupException
              ? 'Evidence could not be saved and its uploaded file could not be removed. Contact support to clean it up.'
              : 'Evidence could not be saved. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEvidence(EvidenceRecord record) async {
    try {
      final url = await widget.repository.openUrl(record);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('No app could open the link.');
      }
    } catch (_) {
      if (mounted) _showError('Evidence could not be opened. Try again.');
    }
  }

  Future<void> _deleteEvidence(EvidenceRecord record) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this evidence?'),
            content: const Text(
              'This removes the saved link or uploaded file and its record links.',
            ),
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
    if (!shouldDelete) return;
    try {
      await widget.repository.deleteEvidence(record);
      if (mounted) {
        setState(() => _records.removeWhere((item) => item.id == record.id));
      }
    } catch (_) {
      if (mounted) _showError('Evidence could not be deleted. Try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pageGutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    return Scaffold(
      appBar: AppBar(title: const Text('Evidence library')),
      body: FutureBuilder<_EvidenceData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Evidence could not be loaded.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _dataFuture = _loadData()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_loaded) {
            _records = snapshot.data!.records;
            _targets = snapshot.data!.targets;
            _loaded = true;
          }
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(pageGutter, 16, pageGutter, 8),
                    padding: EdgeInsets.all(pageGutter < 20 ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppIconTile(
                              icon: Icons.link_outlined,
                              color: AppColors.teal,
                              backgroundColor: AppColors.tealContainer,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Links and files for your work',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Keep supporting links and files together, then connect them to the work they show.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'JPG, PNG, WEBP, PDF, Office documents, TXT, RTF, CSV, MP4, MOV, WEBM, MP3, M4A, WAV, and OGG · Up to ${EvidenceFilePolicy.maxFileLabel}.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const Key('evidenceAddButton'),
                            onPressed: _saving ? null : _addEvidence,
                            icon: const Icon(Icons.add_link),
                            label: const Text('Add evidence'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_saving) const LinearProgressIndicator(),
                  Expanded(
                    child: _records.isEmpty
                        ? const _EvidenceEmptyState()
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              pageGutter,
                              8,
                              pageGutter,
                              24,
                            ),
                            itemCount: _records.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              return Card(
                                child: ListTile(
                                  onTap: () => _openEvidence(record),
                                  leading: AppIconTile(
                                    icon: record.kind == EvidenceKind.file
                                        ? Icons.insert_drive_file_outlined
                                        : Icons.link_outlined,
                                    color: record.kind == EvidenceKind.file
                                        ? AppColors.indigo
                                        : AppColors.teal,
                                    backgroundColor:
                                        record.kind == EvidenceKind.file
                                        ? AppColors.indigoContainer
                                        : AppColors.tealContainer,
                                    size: 44,
                                    iconSize: 21,
                                  ),
                                  title: Text(record.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.kind == EvidenceKind.file
                                            ? '${record.fileName} · ${record.contentType} · ${_formatSize(record.sizeBytes ?? 0)}'
                                            : record.sourceUrl ?? '',
                                      ),
                                      if (record.description.isNotEmpty)
                                        Text(record.description),
                                      if (record.targets.isNotEmpty)
                                        Text(
                                          record.targets
                                              .map(
                                                (target) =>
                                                    '${target.type.label}: ${target.title}',
                                              )
                                              .join(' · '),
                                        ),
                                    ],
                                  ),
                                  isThreeLine:
                                      record.description.isNotEmpty ||
                                      record.targets.isNotEmpty,
                                  trailing: IconButton(
                                    tooltip: 'Delete evidence',
                                    onPressed: _saving
                                        ? null
                                        : () => _deleteEvidence(record),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                              );
                            },
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

class _EvidenceEmptyState extends StatelessWidget {
  const _EvidenceEmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconTile(
            icon: Icons.link_outlined,
            size: 58,
            iconSize: 28,
            color: AppColors.teal,
            backgroundColor: AppColors.tealContainer,
          ),
          SizedBox(height: 12),
          Text('No evidence added yet'),
          SizedBox(height: 6),
          Text('Add a link or upload a file that supports your work.'),
        ],
      ),
    ),
  );
}

class _EvidenceEditor extends StatefulWidget {
  const _EvidenceEditor({required this.targets, required this.filePicker});

  final List<EvidenceTarget> targets;
  final EvidenceFilePicker filePicker;

  @override
  State<_EvidenceEditor> createState() => _EvidenceEditorState();
}

class _EvidenceEditorState extends State<_EvidenceEditor> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  EvidenceKind _kind = EvidenceKind.url;
  PickedEvidenceFile? _file;
  final Set<EvidenceTarget> _selectedTargets = {};
  String? _error;
  bool _picking = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await widget.filePicker.pickFile();
      if (!mounted || file == null) return;
      final error = EvidenceFilePolicy.validate(
        fileName: file.name,
        mimeType: file.mimeType,
        sizeBytes: file.length,
      );
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      setState(() {
        _file = file;
        if (_title.text.trim().isEmpty) {
          final dot = file.name.lastIndexOf('.');
          _title.text = dot > 0 ? file.name.substring(0, dot) : file.name;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'The selected file could not be read.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _submit() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Enter a title for this evidence.');
      return;
    }
    if (_kind == EvidenceKind.url) {
      final uri = EvidenceUrlPolicy.parse(_url.text);
      if (uri == null) {
        setState(
          () => _error =
              'Enter a valid link that starts with http:// or https://.',
        );
        return;
      }
      Navigator.pop(
        context,
        _EvidenceSubmission(
          kind: EvidenceKind.url,
          title: _title.text.trim(),
          description: _description.text.trim(),
          sourceUrl: uri.toString(),
          targets: _selectedTargets.toList(growable: false),
        ),
      );
      return;
    }
    final file = _file;
    if (file == null) {
      setState(() => _error = 'Choose a file to upload.');
      return;
    }
    Navigator.pop(
      context,
      _EvidenceSubmission(
        kind: EvidenceKind.file,
        title: _title.text.trim(),
        description: _description.text.trim(),
        file: file,
        targets: _selectedTargets.toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Add evidence'),
    content: SizedBox(
      width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : 520,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<EvidenceKind>(
                selected: {_kind},
                onSelectionChanged: (value) =>
                    setState(() => _kind = value.first),
                segments: const [
                  ButtonSegment(value: EvidenceKind.url, label: Text('URL')),
                  ButtonSegment(value: EvidenceKind.file, label: Text('File')),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('evidenceTitleField'),
                controller: _title,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              if (_kind == EvidenceKind.url)
                TextField(
                  key: const Key('evidenceUrlField'),
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Web link',
                    hintText: 'https://example.org/work',
                  ),
                )
              else ...[
                OutlinedButton.icon(
                  key: const Key('evidenceChooseFileButton'),
                  onPressed: _picking ? null : _chooseFile,
                  icon: _picking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: Text(
                    _file == null ? 'Choose file' : 'Choose another file',
                  ),
                ),
                if (_file case final file?) ...[
                  const SizedBox(height: 6),
                  Text('${file.name} · ${_formatSize(file.length)}'),
                ],
              ],
              TextField(
                controller: _description,
                maxLength: 3000,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              if (widget.targets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Attach to records (optional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final target in widget.targets)
                      FilterChip(
                        key: Key(
                          'evidenceTarget-${target.type.databaseValue}-${target.id}',
                        ),
                        label: Text('${target.type.label}: ${target.title}'),
                        selected: _selectedTargets.contains(target),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedTargets.add(target);
                          } else {
                            _selectedTargets.remove(target);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
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
        onPressed: _picking ? null : _submit,
        child: const Text('Save evidence'),
      ),
    ],
  );
}

class _EvidenceSubmission {
  const _EvidenceSubmission({
    required this.kind,
    required this.title,
    required this.description,
    required this.targets,
    this.sourceUrl,
    this.file,
  });

  final EvidenceKind kind;
  final String title;
  final String description;
  final String? sourceUrl;
  final PickedEvidenceFile? file;
  final List<EvidenceTarget> targets;
}

class _EvidenceData {
  const _EvidenceData(this.records, this.targets);
  final List<EvidenceRecord> records;
  final List<EvidenceTarget> targets;
}

String _formatSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
}
