import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/resume_exporter.dart';
import '../domain/resume_content.dart';
import '../domain/resume_layout.dart';

class ResumePreviewScreen extends StatefulWidget {
  const ResumePreviewScreen({super.key, required this.content});

  final ResumeContent content;

  @override
  State<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends State<ResumePreviewScreen> {
  ResumeLayout _layout = ResumeLayout.atsFriendly;
  bool _includePhoto = false;
  bool _saving = false;

  bool get _hasContent =>
      widget.content.displayName.isNotEmpty ||
      widget.content.headline.isNotEmpty ||
      widget.content.summary.isNotEmpty ||
      widget.content.contactDetails.isNotEmpty ||
      widget.content.sections.isNotEmpty;

  Future<void> _export({required bool asPdf}) async {
    if (_saving ||
        !_hasContent ||
        widget.content.unavailableSections.isNotEmpty) {
      return;
    }
    setState(() => _saving = true);
    final extension = asPdf ? 'pdf' : 'docx';
    try {
      final Uint8List bytes = asPdf
          ? await ResumeExporter.toPdf(
              widget.content,
              layout: _layout,
              includePhoto: _includePhoto,
            )
          : await ResumeExporter.toDocx(
              widget.content,
              layout: _layout,
              includePhoto: _includePhoto,
            );
      final saved = await FilePicker.saveFile(
        fileName: ResumeExporter.fileNameFor(
          widget.content.displayName,
          extension,
        ),
        bytes: bytes,
        mimeType: asPdf
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        type: FileType.custom,
        allowedExtensions: [extension],
        dialogTitle: asPdf ? 'Save resume PDF' : 'Save resume DOCX',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved == null
                ? 'Resume export cancelled.'
                : 'Resume ${extension.toUpperCase()} saved.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resume ${extension.toUpperCase()} could not be saved: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = AppTheme.pageGutterFor(MediaQuery.sizeOf(context).width);
    final hasUnavailableSections =
        widget.content.unavailableSections.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Resume preview')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 32),
              children: [
                Text('Resume layout', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<ResumeLayout>(
                  segments: const [
                    ButtonSegment(
                      value: ResumeLayout.atsFriendly,
                      label: Text('ATS-friendly format'),
                    ),
                    ButtonSegment(
                      value: ResumeLayout.visual,
                      label: Text('Photo resume'),
                    ),
                  ],
                  selected: {_layout},
                  onSelectionChanged: _saving
                      ? null
                      : (selection) => setState(() {
                          _layout = selection.first;
                          if (_layout != ResumeLayout.visual) {
                            _includePhoto = false;
                          }
                        }),
                ),
                const SizedBox(height: 10),
                Text(
                  _layout == ResumeLayout.atsFriendly
                      ? 'This text-first layout uses a single reading column and standard section headings. Parsing varies by applicant tracking system, and no format can guarantee acceptance.'
                      : 'This visual layout keeps the same saved information. Add your profile photo only if you want it on this resume.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_layout == ResumeLayout.visual &&
                    widget.content.photoBytes != null)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _includePhoto,
                    onChanged: _saving
                        ? null
                        : (value) =>
                              setState(() => _includePhoto = value ?? false),
                    title: const Text('Include profile photo'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                if (hasUnavailableSections) ...[
                  const SizedBox(height: 16),
                  _UnavailableNotice(
                    sections: widget.content.unavailableSections,
                  ),
                ],
                const SizedBox(height: 20),
                _ResumeDocument(
                  content: widget.content,
                  layout: _layout,
                  includePhoto: _includePhoto,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          _saving || !_hasContent || hasUnavailableSections
                          ? null
                          : () => _export(asPdf: true),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Download PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _saving || !_hasContent || hasUnavailableSections
                          ? null
                          : () => _export(asPdf: false),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Download DOCX'),
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
}

class _ResumeDocument extends StatelessWidget {
  const _ResumeDocument({
    required this.content,
    required this.layout,
    required this.includePhoto,
  });

  final ResumeContent content;
  final ResumeLayout layout;
  final bool includePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoBytes = layout == ResumeLayout.visual && includePhoto
        ? content.photoBytes
        : null;
    return Card(
      color: layout == ResumeLayout.visual
          ? theme.colorScheme.surfaceContainerLow
          : null,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoBytes != null ||
                content.displayName.isNotEmpty ||
                content.headline.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photoBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          photoBytes,
                          key: const Key('resumePreviewPhoto'),
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (content.displayName.isNotEmpty)
                          SelectableText(
                            content.displayName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: layout == ResumeLayout.visual
                                  ? AppColors.deepNavy
                                  : null,
                            ),
                          ),
                        if (content.headline.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          SelectableText(
                            content.headline,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            for (final detail in content.contactDetails)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText('${detail.label}: ${detail.value}'),
              ),
            if (content.summary.isNotEmpty) ...[
              _ResumeHeading('Summary'),
              SelectableText(content.summary),
            ],
            for (final section in content.sections) ...[
              _ResumeHeading(section.heading),
              for (final entry in section.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SelectableText(
                    entry.title,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (entry.subtitle.isNotEmpty) SelectableText(entry.subtitle),
                if (entry.dateRange.isNotEmpty) SelectableText(entry.dateRange),
                if (entry.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText(entry.description),
                  ),
              ],
            ],
            if (content.displayName.isEmpty &&
                content.summary.isEmpty &&
                content.contactDetails.isEmpty &&
                content.sections.isEmpty)
              const Text('Add profile and work details to build your resume.'),
          ],
        ),
      ),
    );
  }
}

class _ResumeHeading extends StatelessWidget {
  const _ResumeHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          const Divider(height: 8),
        ],
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        'Some saved information could not be loaded: ${sections.join(', ')}. '
        'Return to your portfolio and refresh before exporting.',
      ),
    ),
  );
}
