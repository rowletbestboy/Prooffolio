import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon_tile.dart';
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
  double _zoom = 1;
  int _currentPage = 0;
  int _pageCount = 0;
  final _pageController = PageController();
  final _pdfTransformationController = TransformationController();

  bool get _hasContent =>
      widget.content.displayName.isNotEmpty ||
      widget.content.headline.isNotEmpty ||
      widget.content.summary.isNotEmpty ||
      widget.content.contactDetails.isNotEmpty ||
      widget.content.sections.isNotEmpty;

  @override
  void dispose() {
    _pageController.dispose();
    _pdfTransformationController.dispose();
    super.dispose();
  }

  void _changeZoom(double amount) {
    final nextZoom = (_zoom + amount).clamp(.7, 1.6).toDouble();
    setState(() => _zoom = nextZoom);
    _pdfTransformationController.value = Matrix4.identity()
      ..scaleByDouble(nextZoom, nextZoom, 1, 1);
  }

  void _changeLayout(ResumeLayout layout) {
    setState(() {
      _layout = layout;
      _pageCount = 0;
      _currentPage = 0;
      if (layout != ResumeLayout.visual) _includePhoto = false;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _pdfTransformationController.value = Matrix4.identity();
  }

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
      backgroundColor: AppColors.cloudWhite,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 12,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resume Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'Review and refine your resume.',
              style: TextStyle(
                color: AppColors.inverseIndigo,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            key: const Key('resumeOptionsMenu'),
            tooltip: 'Resume options',
            enabled: !_saving && _hasContent && !hasUnavailableSections,
            onSelected: (value) {
              if (value == 'docx') _export(asPdf: false);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'docx', child: Text('Export DOCX')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('editResumeButton'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Resume'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const Key('exportResumePdfButton'),
                  onPressed: _saving || !_hasContent || hasUnavailableSections
                      ? null
                      : () => _export(asPdf: true),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_saving ? 'Exporting' : 'Export PDF'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResumeIntroCard(content: widget.content),
                    const SizedBox(height: 14),
                    SegmentedButton<ResumeLayout>(
                      segments: const [
                        ButtonSegment(
                          value: ResumeLayout.atsFriendly,
                          label: Text('ATS-friendly'),
                        ),
                        ButtonSegment(
                          value: ResumeLayout.visual,
                          label: Text('Photo resume'),
                        ),
                      ],
                      selected: {_layout},
                      onSelectionChanged: _saving
                          ? null
                          : (selection) => _changeLayout(selection.first),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.indigo,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _layout == ResumeLayout.atsFriendly
                                ? 'This text-first layout uses a single reading column and standard section headings. Parsing varies by applicant tracking system, and no format can guarantee acceptance.'
                                : 'This visual layout keeps the same saved information. Add your profile photo only if you want it on this resume.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (_layout == ResumeLayout.visual &&
                        widget.content.photoBytes != null)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _includePhoto,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _includePhoto = value ?? false,
                              ),
                        title: const Text('Include profile photo'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    if (hasUnavailableSections) ...[
                      const SizedBox(height: 14),
                      _UnavailableNotice(
                        sections: widget.content.unavailableSections,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _PdfPreviewCard(
                      pageController: _pageController,
                      transformationController: _pdfTransformationController,
                      zoom: _zoom,
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      onZoomIn: () => _changeZoom(.1),
                      onZoomOut: () => _changeZoom(-.1),
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      onPagesLoaded: (count) {
                        if (!mounted || count <= 0 || count == _pageCount) {
                          return;
                        }
                        setState(() {
                          _pageCount = count;
                          _currentPage = _currentPage.clamp(0, count - 1);
                        });
                      },
                      pdfBuild: (_) => ResumeExporter.toPdf(
                        widget.content,
                        layout: _layout,
                        includePhoto: _includePhoto,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ResumeReadiness(content: widget.content),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeIntroCard extends StatelessWidget {
  const _ResumeIntroCard({required this.content});

  final ResumeContent content;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const AppIconTile(
        icon: Icons.description_outlined,
        color: AppColors.indigo,
        backgroundColor: AppColors.indigoContainer,
        size: 56,
        iconSize: 26,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Resume', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              'Make sure everything looks good before exporting your PDF.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tealContainer,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'Draft',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.teal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _PdfPreviewCard extends StatelessWidget {
  const _PdfPreviewCard({
    required this.pageController,
    required this.transformationController,
    required this.zoom,
    required this.currentPage,
    required this.pageCount,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onPageChanged,
    required this.onPagesLoaded,
    required this.pdfBuild,
  });

  final PageController pageController;
  final TransformationController transformationController;
  final double zoom;
  final int currentPage;
  final int pageCount;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPagesLoaded;
  final LayoutCallback pdfBuild;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      key: const Key('resumePdfPreviewCard'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'PDF Preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: 'Zoom out',
                onPressed: zoom <= .7 ? null : onZoomOut,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_out),
              ),
              Text(
                '${(zoom * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              IconButton(
                tooltip: 'Zoom in',
                onPressed: zoom >= 1.6 ? null : onZoomIn,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.zoom_in),
              ),
            ],
          ),
          SizedBox(
            height: width > 600 ? 760 : 540,
            child: PdfPreview.builder(
              key: const Key('resumePdfPreview'),
              build: pdfBuild,
              pagesBuilder: (context, pages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onPagesLoaded(pages.length);
                });
                return PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final pageWidth = constraints.maxWidth - 16;
                        final pageHeight = constraints.maxHeight - 16;
                        final fittedWidth =
                            pageWidth < pageHeight * page.aspectRatio
                            ? pageWidth
                            : pageHeight * page.aspectRatio;
                        return Center(
                          child: InteractiveViewer(
                            transformationController: transformationController,
                            minScale: .7,
                            maxScale: 2.5,
                            boundaryMargin: const EdgeInsets.all(32),
                            child: Container(
                              width: fittedWidth,
                              height: fittedWidth / page.aspectRatio,
                              color: AppColors.white,
                              alignment: Alignment.center,
                              child: Image(
                                image: page.image,
                                fit: BoxFit.contain,
                                semanticLabel:
                                    'Resume page ${index + 1} of ${pages.length}',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
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
          if (pageCount > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      for (var index = 0; index < pageCount; index++)
                        IconButton(
                          tooltip: 'Preview page ${index + 1}',
                          onPressed: () => pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.circle,
                            size: 8,
                            color: index == currentPage
                                ? AppColors.indigo
                                : AppColors.lightSlate,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${currentPage + 1} of $pageCount',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumeReadiness extends StatelessWidget {
  const _ResumeReadiness({required this.content});

  final ResumeContent content;

  @override
  Widget build(BuildContext context) {
    final items = _readinessItems(content);
    final completed = items
        .where((item) => item.complete && !item.unavailable)
        .length;
    final theme = Theme.of(context);
    return Container(
      key: const Key('resumeReadinessCard'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightSlate),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AppIconTile(
                icon: Icons.fact_check_outlined,
                color: AppColors.white,
                backgroundColor: AppColors.indigo,
                size: 30,
                iconSize: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Resume readiness',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '$completed of ${items.length} sections',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: LinearProgressIndicator(
              value: completed / items.length,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
              backgroundColor: AppColors.lightSlate,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 3),
              child: Row(
                children: [
                  Icon(
                    item.complete
                        ? Icons.check_circle
                        : item.unavailable
                        ? Icons.error_outline
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: item.complete
                        ? AppColors.teal
                        : item.unavailable
                        ? AppColors.amber
                        : AppColors.slateGray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.unavailable
                          ? '${item.label} could not be loaded'
                          : item.complete
                          ? item.label
                          : '${item.label.replaceFirst(' included', '').replaceFirst(' added', '')} missing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: item.unavailable
                            ? AppColors.amber
                            : AppColors.slateGray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReadinessItem {
  const _ReadinessItem({
    required this.label,
    required this.complete,
    this.unavailable = false,
  });

  final String label;
  final bool complete;
  final bool unavailable;
}

List<_ReadinessItem> _readinessItems(ResumeContent content) {
  final sectionNames = content.sections
      .map((section) => section.heading)
      .toSet();
  bool unavailable(String section) =>
      content.unavailableSections.contains(section);
  bool has(String section) => sectionNames.contains(section);
  return [
    _ReadinessItem(
      label: 'Profile information complete',
      complete:
          content.displayName.trim().isNotEmpty &&
          (content.headline.trim().isNotEmpty ||
              content.summary.trim().isNotEmpty),
      unavailable: unavailable('Profile'),
    ),
    _ReadinessItem(
      label: 'Skills and projects included',
      complete: has('Skills') && has('Projects'),
      unavailable: unavailable('Skills') || unavailable('Projects'),
    ),
    _ReadinessItem(
      label: 'Education included',
      complete: has('Education'),
      unavailable: unavailable('Education'),
    ),
    _ReadinessItem(
      label: 'Experience included',
      complete: has('Experience'),
      unavailable: unavailable('Experience'),
    ),
    _ReadinessItem(
      label: 'Contact details added',
      complete: content.contactDetails.isNotEmpty,
      unavailable: unavailable('Profile'),
    ),
  ];
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
