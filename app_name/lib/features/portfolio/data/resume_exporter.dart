import 'dart:typed_data';

import 'package:docx_dart/docx_dart.dart' as docx;
import 'package:image/image.dart' as image;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/resume_content.dart';
import '../domain/resume_layout.dart';

abstract final class ResumeExporter {
  static Future<Uint8List> toPdf(
    ResumeContent content, {
    ResumeLayout layout = ResumeLayout.atsFriendly,
    bool includePhoto = false,
  }) async {
    final photo = _selectedPhoto(content, layout, includePhoto);
    final document = layout == ResumeLayout.atsFriendly
        ? _atsFriendlyDocument(content)
        : _visualDocument(content, photo);
    return document.save();
  }

  static Future<Uint8List> toDocx(
    ResumeContent content, {
    ResumeLayout layout = ResumeLayout.atsFriendly,
    bool includePhoto = false,
  }) async {
    final document = docx.loadDocxDocument();
    final photo = _selectedPhoto(content, layout, includePhoto);
    if (photo != null) {
      document.addPicture(photo, width: docx.Inches(1));
    }
    if (content.displayName.isNotEmpty) {
      document.addHeading(text: content.displayName, level: 0);
    }
    if (content.headline.isNotEmpty) {
      document.addParagraph(text: content.headline);
    }
    for (final detail in content.contactDetails) {
      document.addParagraph(text: '${detail.label}: ${detail.value}');
    }
    if (content.summary.isNotEmpty) {
      document.addHeading(text: 'Summary', level: 1);
      document.addParagraph(text: content.summary);
    }
    for (final section in content.sections) {
      document.addHeading(text: section.heading, level: 1);
      for (final entry in section.entries) {
        document.addHeading(text: entry.title, level: 2);
        if (entry.subtitle.isNotEmpty) {
          document.addParagraph(text: entry.subtitle);
        }
        if (entry.dateRange.isNotEmpty) {
          document.addParagraph(text: entry.dateRange);
        }
        if (entry.description.isNotEmpty) {
          document.addParagraph(text: entry.description);
        }
      }
    }
    final bytes = BytesBuilder();
    document.save(bytes);
    return bytes.takeBytes();
  }

  static String fileNameFor(String displayName, String extension) {
    final normalizedExtension = extension.toLowerCase();
    if (normalizedExtension != 'pdf' && normalizedExtension != 'docx') {
      throw ArgumentError.value(extension, 'extension', 'Use pdf or docx.');
    }
    final name = displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return name.isEmpty
        ? 'resume.$normalizedExtension'
        : '$name-resume.$normalizedExtension';
  }
}

pw.Document _atsFriendlyDocument(ResumeContent content) {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(46, 38, 46, 38),
      build: (context) => [
        if (content.displayName.isNotEmpty)
          pw.Center(
            child: pw.Text(
              content.displayName.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 25, letterSpacing: 2.2),
            ),
          ),
        if (content.headline.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Center(
              child: pw.Text(
                content.headline.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        if (content.contactDetails.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 7, bottom: 9),
            child: pw.Center(
              child: pw.Text(
                content.contactDetails
                    .map((detail) => detail.value)
                    .join(' | '),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ),
        if (content.displayName.isNotEmpty ||
            content.headline.isNotEmpty ||
            content.contactDetails.isNotEmpty)
          pw.Divider(thickness: 1.2, color: PdfColors.black),
        if (content.summary.isNotEmpty) ...[
          _atsSectionHeading('Summary'),
          pw.Text(content.summary, style: const pw.TextStyle(fontSize: 9)),
        ],
        for (final section in content.sections) ...[
          _atsSectionHeading(
            section.heading == 'Experience'
                ? 'Professional Experience'
                : section.heading,
          ),
          if (section.heading == 'Skills')
            _atsSkills(section.entries)
          else
            for (final entry in section.entries) _atsEntry(entry),
        ],
      ],
    ),
  );
  return document;
}

pw.Document _visualDocument(ResumeContent content, Uint8List? photo) {
  const sidebarWidth = 160.0;
  const columnGap = 24.0;
  final document = pw.Document();
  final photoImage = photo == null ? null : pw.MemoryImage(photo);
  final sidebarColor = PdfColor.fromHex('#F1F1F1');
  final pageTheme = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 30),
    buildBackground: (context) => pw.Stack(
      children: [
        pw.Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: pw.Container(color: PdfColors.white),
        ),
        pw.Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: pw.SizedBox(
            width: sidebarWidth,
            child: pw.Container(color: sidebarColor),
          ),
        ),
      ],
    ),
  );
  final sidebarSections = content.sections.where(
    (section) => section.heading == 'Education' || section.heading == 'Skills',
  );
  final mainSections = content.sections.where(
    (section) => section.heading != 'Education' && section.heading != 'Skills',
  );
  document.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      build: (context) => [
        pw.Partitions(
          children: [
            pw.Partition(
              width: sidebarWidth,
              child: pw.Padding(
                padding: pw.EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: photoImage == null ? 0 : 24,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    if (photoImage != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 14),
                        child: pw.Center(
                          child: pw.ClipOval(
                            child: pw.SizedBox(
                              width: 66,
                              height: 66,
                              child: pw.Image(photoImage, fit: pw.BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    if (content.contactDetails.isNotEmpty) ...[
                      _visualSectionHeading('Contact Me'),
                      for (final detail in content.contactDetails)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            '${detail.label}: ${detail.value}',
                            style: const pw.TextStyle(fontSize: 7.5),
                          ),
                        ),
                    ],
                    for (final section in sidebarSections) ...[
                      _visualSectionHeading(section.heading),
                      if (section.heading == 'Skills')
                        for (final entry in section.entries)
                          _visualBullet(entry.title)
                      else
                        for (final entry in section.entries)
                          _visualEntry(entry, compact: true),
                    ],
                  ],
                ),
              ),
            ),
            pw.Partition(
              width: columnGap,
              child: pw.Column(children: []),
            ),
            pw.Partition(
              flex: 1,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (content.displayName.isNotEmpty)
                    pw.Text(
                      content.displayName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                  if (content.headline.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3, bottom: 18),
                      child: pw.Text(
                        content.headline,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  if (content.summary.isNotEmpty) ...[
                    _visualSectionHeading('About Me'),
                    pw.Text(
                      content.summary,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                  for (final section in mainSections) ...[
                    _visualSectionHeading(
                      section.heading == 'Experience'
                          ? 'Work Experience'
                          : section.heading,
                    ),
                    for (final entry in section.entries) _visualEntry(entry),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return document;
}

pw.Widget _atsSectionHeading(String heading) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        heading.toUpperCase(),
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.Divider(height: 4, thickness: 0.7, color: PdfColors.black),
    ],
  ),
);

pw.Widget _atsEntry(ResumeEntry entry) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 6),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              entry.title,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          if (entry.dateRange.isNotEmpty)
            pw.Text(entry.dateRange, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
      if (entry.subtitle.isNotEmpty)
        pw.Text(entry.subtitle, style: const pw.TextStyle(fontSize: 8)),
      ..._pdfBullets(entry.description, fontSize: 8),
    ],
  ),
);

pw.Widget _atsSkills(List<ResumeEntry> entries) => pw.Wrap(
  spacing: 10,
  runSpacing: 2,
  children: [
    for (final entry in entries)
      pw.SizedBox(
        width: 155,
        child: pw.Bullet(
          text: entry.title,
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
  ],
);

pw.Widget _visualSectionHeading(String heading) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 13, bottom: 6),
  child: pw.Text(
    heading.toUpperCase(),
    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
  ),
);

pw.Widget _visualEntry(ResumeEntry entry, {bool compact = false}) => pw.Padding(
  padding: pw.EdgeInsets.only(bottom: compact ? 7 : 9),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              entry.title,
              style: pw.TextStyle(
                fontSize: compact ? 7.5 : 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (!compact && entry.dateRange.isNotEmpty)
            pw.Text(entry.dateRange, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
      if (entry.subtitle.isNotEmpty)
        pw.Text(entry.subtitle, style: const pw.TextStyle(fontSize: 7.5)),
      if (compact && entry.dateRange.isNotEmpty)
        pw.Text(entry.dateRange, style: const pw.TextStyle(fontSize: 7)),
      if (!compact) ..._pdfBullets(entry.description, fontSize: 7.5),
      if (compact && entry.description.isNotEmpty)
        pw.Text(entry.description, style: const pw.TextStyle(fontSize: 7)),
    ],
  ),
);

pw.Widget _visualBullet(String text) => pw.Bullet(
  text: text,
  style: const pw.TextStyle(fontSize: 7.5),
  padding: const pw.EdgeInsets.only(bottom: 3),
);

List<pw.Widget> _pdfBullets(String text, {required double fontSize}) {
  final paragraphs = text
      .split(RegExp(r'[\r\n]+'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty);
  return [
    for (final paragraph in paragraphs)
      for (final chunk in _pdfParagraphs(paragraph))
        pw.Bullet(
          text: chunk,
          style: pw.TextStyle(fontSize: fontSize),
          padding: const pw.EdgeInsets.only(top: 2),
        ),
  ];
}

Uint8List? _selectedPhoto(
  ResumeContent content,
  ResumeLayout layout,
  bool includePhoto,
) {
  if (layout != ResumeLayout.visual || !includePhoto) return null;
  final photoBytes = content.photoBytes;
  if (photoBytes == null) return null;
  final decoded = image.decodeImage(photoBytes);
  if (decoded == null) throw const FormatException('Profile photo is invalid.');
  final largestSide = decoded.width > decoded.height
      ? decoded.width
      : decoded.height;
  final resized = largestSide > 600
      ? image.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 600 : null,
          height: decoded.height > decoded.width ? 600 : null,
        )
      : decoded;
  return Uint8List.fromList(image.encodePng(resized));
}

Iterable<String> _pdfParagraphs(String text) sync* {
  final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  var paragraph = '';
  for (final word in words) {
    final candidate = paragraph.isEmpty ? word : '$paragraph $word';
    if (candidate.length > 600 && paragraph.isNotEmpty) {
      yield paragraph;
      paragraph = word;
    } else {
      paragraph = candidate;
    }
  }
  if (paragraph.isNotEmpty) yield paragraph;
}
