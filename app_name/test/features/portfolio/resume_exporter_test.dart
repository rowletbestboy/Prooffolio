import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:app_name/features/portfolio/data/resume_exporter.dart';
import 'package:app_name/features/portfolio/domain/resume_content.dart';
import 'package:app_name/features/portfolio/domain/resume_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import 'resume_test_fixtures.dart';

void main() {
  test('PDF export flows long text across multiple pages', () async {
    final content = ResumeContent(
      displayName: 'Alex Rivera',
      headline: '',
      summary: '',
      contactDetails: const [],
      sections: [
        ResumeSection(
          heading: 'Experience',
          entries: [
            ResumeEntry(
              title: 'Community designer',
              description: List.filled(
                1200,
                'A detailed contribution that remains selectable text.',
              ).join(' '),
            ),
          ],
        ),
      ],
      unavailableSections: const [],
      photoBytes: null,
    );

    final bytes = await ResumeExporter.toPdf(content);
    final pdf = latin1.decode(bytes);
    final pageCount = RegExp(r'/Type\s*/Page\b').allMatches(pdf).length;

    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
    expect(pageCount, greaterThan(1));
  });

  test('visual PDF keeps the main heading clear of the sidebar', () async {
    final content = ResumeContent.fromPortfolioContent(
      portfolioContentWithResumeData(photoBytes: tinyPngBytes()),
    );
    final bytes = await ResumeExporter.toPdf(
      content,
      layout: ResumeLayout.visual,
      includePhoto: true,
    );
    final pdf = _firstCompressedPdfStream(bytes);
    final headingIndex = pdf.indexOf('[(ALEX)]TJ');
    expect(headingIndex, greaterThanOrEqualTo(0));

    final headingContent = pdf.substring(0, headingIndex);
    expect(headingContent, contains('1 0 0 1 184 0 cm'));
  });

  test(
    'visual PDF insets the photo and sidebar text from page edges',
    () async {
      final content = ResumeContent.fromPortfolioContent(
        portfolioContentWithResumeData(photoBytes: tinyPngBytes()),
      );
      final bytes = await ResumeExporter.toPdf(
        content,
        layout: ResumeLayout.visual,
        includePhoto: true,
      );
      final stream = _firstCompressedPdfStream(bytes);
      final imageDraw = RegExp(r'/I\d+ Do').firstMatch(stream);

      expect(imageDraw, isNotNull);
      final photoPosition = _translationAt(stream, imageDraw!.group(0)!);
      final sidebarTextPosition = _translationAt(stream, '[(SKILLS)]TJ');

      expect(sidebarTextPosition.$1, closeTo(40, .01));
      expect(PdfPageFormat.a4.height - photoPosition.$2 - 66, closeTo(54, .1));
    },
  );

  test('DOCX export uses headings and ordinary text paragraphs', () async {
    final content = ResumeContent.fromPortfolioContent(
      portfolioContentWithResumeData(),
    );

    final bytes = await ResumeExporter.toDocx(content);
    final document = ZipDecoder().decodeBytes(bytes);
    final documentXml = utf8.decode(
      document.findFile('word/document.xml')!.content,
    );

    expect(bytes.take(2), [0x50, 0x4b]);
    expect(documentXml, contains('Alex Rivera'));
    expect(documentXml, contains('Experience'));
    expect(documentXml, contains('Product designer'));
    expect(documentXml, isNot(contains('<w:tbl')));
    expect(documentXml, isNot(contains('Private proof file')));
  });

  test(
    'visual exports include a selected photo while text-first omits it',
    () async {
      final photo = tinyPngBytes();
      final content = ResumeContent.fromPortfolioContent(
        portfolioContentWithResumeData(photoBytes: photo),
      );

      final atsPdf = await ResumeExporter.toPdf(
        content,
        layout: ResumeLayout.atsFriendly,
        includePhoto: true,
      );
      final visualDocx = await ResumeExporter.toDocx(
        content,
        layout: ResumeLayout.visual,
        includePhoto: true,
      );
      final visualArchive = ZipDecoder().decodeBytes(visualDocx);

      expect(latin1.decode(atsPdf), isNot(contains('/Subtype /Image')));
      expect(
        visualArchive.files.any((file) => file.name.startsWith('word/media/')),
        isTrue,
      );
    },
  );

  test('filename is sanitized from the display name', () {
    expect(
      ResumeExporter.fileNameFor(' Alex Rivera / Designer ', 'pdf'),
      'alex-rivera-designer-resume.pdf',
    );
    expect(ResumeExporter.fileNameFor('', 'docx'), 'resume.docx');
  });
}

String _firstCompressedPdfStream(Uint8List bytes) {
  final pdf = latin1.decode(bytes);
  final streams = RegExp(
    r'stream\r?\n([\s\S]*?)\r?\nendstream',
  ).allMatches(pdf);

  for (final stream in streams) {
    try {
      final decoded = latin1.decode(
        ZLibDecoder().decodeBytes(latin1.encode(stream.group(1)!)),
      );
      if (decoded.contains('BT')) return decoded;
    } on FormatException {
      continue;
    }
  }

  throw StateError('PDF export did not include a readable content stream.');
}

(double, double) _translationAt(String stream, String marker) {
  final markerIndex = stream.indexOf(marker);
  if (markerIndex < 0) throw StateError('PDF stream did not contain $marker.');
  final stack = <(double, double)>[];
  var x = 0.0;
  var y = 0.0;
  final operators = RegExp(
    r'\b(q|Q)\b|(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+'
    r'(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+'
    r'(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s+cm',
  );
  for (final operator in operators.allMatches(
    stream.substring(0, markerIndex),
  )) {
    if (operator.group(1) == 'q') {
      stack.add((x, y));
    } else if (operator.group(1) == 'Q') {
      final previous = stack.removeLast();
      x = previous.$1;
      y = previous.$2;
    } else {
      x += double.parse(operator.group(6)!);
      y += double.parse(operator.group(7)!);
    }
  }
  return (x, y);
}
