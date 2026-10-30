import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_page_app_bar.dart';
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
      appBar: const AppPageAppBar(title: 'Resume preview'),
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
                Text('PDF preview', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.sizeOf(context).width > 600 ? 860 : 620,
                  child: PdfPreview(
                    key: const Key('resumePdfPreview'),
                    build: (_) => ResumeExporter.toPdf(
                      widget.content,
                      layout: _layout,
                      includePhoto: _includePhoto,
                    ),
                    loadingWidget: const Center(
                      child: Text('Preparing PDF preview...'),
                    ),
                    initialPageFormat: PdfPageFormat.a4,
                    maxPageWidth: 620,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    useActions: false,
                  ),
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

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.errorContainer,
    borderRadius: BorderRadius.circular(AppTheme.controlRadius),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Text(
        'Some saved information could not be loaded: ${sections.join(', ')}. '
        'Return to your portfolio and refresh before exporting.',
      ),
    ),
  );
}
