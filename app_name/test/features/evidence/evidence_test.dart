import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/evidence/domain/evidence.dart';

void main() {
  test('URL policy trims input and accepts only absolute HTTP(S) URLs', () {
    expect(
      EvidenceUrlPolicy.parse('  https://proof.example/work  ')?.toString(),
      'https://proof.example/work',
    );
    expect(EvidenceUrlPolicy.parse('http://proof.example'), isNotNull);
    expect(EvidenceUrlPolicy.parse('javascript:alert(1)'), isNull);
    expect(EvidenceUrlPolicy.parse('/relative/path'), isNull);
    expect(EvidenceUrlPolicy.parse('https://'), isNull);
  });

  test(
    'file policy accepts allow-listed extensions with matching MIME types',
    () {
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'garden-photo.JPEG',
          mimeType: 'image/jpeg',
          sizeBytes: 1,
        ),
        isNull,
      );
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'course-notes.docx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          sizeBytes: 1,
        ),
        isNull,
      );
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'interview.m4a',
          mimeType: 'audio/mp4',
          sizeBytes: 1,
        ),
        isNull,
      );
    },
  );

  test('file policy uses the extension when the picker omits MIME type', () {
    expect(
      EvidenceFilePolicy.validate(
        fileName: 'work-sample.pdf',
        mimeType: null,
        sizeBytes: 1,
      ),
      isNull,
    );
    expect(
      EvidenceFilePolicy.contentTypeFor('work-sample.pdf'),
      'application/pdf',
    );
  });

  test(
    'file policy rejects unsupported formats, mismatches, and empty files',
    () {
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'installer.exe',
          mimeType: 'application/octet-stream',
          sizeBytes: 1,
        ),
        isNotNull,
      );
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'photo.png',
          mimeType: 'image/jpeg',
          sizeBytes: 1,
        ),
        isNotNull,
      );
      expect(
        EvidenceFilePolicy.validate(
          fileName: 'empty.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 0,
        ),
        isNotNull,
      );
    },
  );

  test('file policy enforces the configured size boundary', () {
    expect(
      EvidenceFilePolicy.validate(
        fileName: 'within-limit.pdf',
        mimeType: 'application/pdf',
        sizeBytes: EvidenceFilePolicy.maxFileBytes,
      ),
      isNull,
    );
    expect(
      EvidenceFilePolicy.validate(
        fileName: 'over-limit.pdf',
        mimeType: 'application/pdf',
        sizeBytes: EvidenceFilePolicy.maxFileBytes + 1,
      ),
      isNotNull,
    );
  });

  test('evidence serialization preserves file, URL, and target values', () {
    const urlEvidence = EvidenceDraft.url(
      title: 'Community garden report',
      sourceUrl: 'https://proof.example/report',
      description: 'Published project notes.',
    );
    expect(urlEvidence.toDatabaseFields(), {
      'kind': 'url',
      'title': 'Community garden report',
      'description': 'Published project notes.',
      'source_url': 'https://proof.example/report',
      'file_name': null,
      'content_type': null,
      'size_bytes': null,
      'storage_path': null,
    });

    const fileEvidence = EvidenceDraft.file(
      title: 'Garden photo',
      fileName: 'garden.webp',
      contentType: 'image/webp',
      sizeBytes: 256,
      storagePath: 'user-1/evidence-file.webp',
    );
    final record = EvidenceRecord.fromJson({
      'id': 'evidence-1',
      'user_id': 'user-1',
      ...fileEvidence.toDatabaseFields(),
      'created_at': '2026-10-21T00:00:00Z',
      'updated_at': '2026-10-21T00:00:00Z',
    });
    expect(record.kind, EvidenceKind.file);
    expect(record.fileName, 'garden.webp');
    expect(record.sizeBytes, 256);
    expect(record.targets, isEmpty);

    expect(
      EvidenceTargetType.fromDatabase('portfolio_record'),
      EvidenceTargetType.portfolioRecord,
    );
    expect(EvidenceTargetType.project.databaseValue, 'project');
  });
}
