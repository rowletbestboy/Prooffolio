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
    final document = pw.Document();
    final photo = _selectedPhoto(content, layout, includePhoto);
    final photoImage = photo == null ? null : pw.MemoryImage(photo);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 44),
        build: (context) => [
          if (photoImage != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Image(photoImage, width: 72, height: 72),
            ),
          if (content.displayName.isNotEmpty)
            pw.Text(
              content.displayName,
              style: pw.TextStyle(
                fontSize: layout == ResumeLayout.visual ? 25 : 21,
                fontWeight: pw.FontWeight.bold,
                color: layout == ResumeLayout.visual
                    ? PdfColors.teal800
                    : PdfColors.black,
              ),
            ),
          if (content.headline.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(content.headline),
            ),
          for (final detail in content.contactDetails)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('${detail.label}: ${detail.value}'),
            ),
          if (content.summary.isNotEmpty) ...[
            _pdfHeading('Summary', layout),
            for (final paragraph in _pdfParagraphs(content.summary))
              pw.Text(paragraph),
          ],
          for (final section in content.sections) ...[
            _pdfHeading(section.heading, layout),
            for (final entry in section.entries) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                  entry.title,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (entry.subtitle.isNotEmpty) pw.Text(entry.subtitle),
              if (entry.dateRange.isNotEmpty) pw.Text(entry.dateRange),
              if (entry.description.isNotEmpty)
                for (final paragraph in _pdfParagraphs(entry.description))
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(paragraph),
                  ),
            ],
          ],
        ],
      ),
    );
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

pw.Widget _pdfHeading(String heading, ResumeLayout layout) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 15, bottom: 5),
  child: pw.Text(
    heading,
    style: pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: layout == ResumeLayout.visual
          ? PdfColors.teal800
          : PdfColors.black,
    ),
  ),
);

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
