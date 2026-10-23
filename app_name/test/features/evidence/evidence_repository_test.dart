import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/evidence/data/evidence_repository.dart';
import 'package:app_name/features/evidence/domain/evidence.dart';

void main() {
  test('upload stores a private object and links its metadata', () async {
    final database = _FakeEvidenceDataSource();
    final storage = _FakeEvidenceObjectStorage();
    final repository = _repository(database, storage);
    const target = EvidenceTarget(
      type: EvidenceTargetType.project,
      id: 'project-1',
      title: 'Community garden',
    );

    final record = await repository.uploadFile(
      title: 'Garden photo',
      fileName: 'garden.JPG',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList([1, 2, 3]),
      targets: const [target],
    );

    expect(record.kind, EvidenceKind.file);
    expect(record.fileName, 'garden.JPG');
    expect(record.contentType, 'image/jpeg');
    expect(record.targets, [target]);
    expect(storage.uploadedPath, startsWith('user-1/'));
    expect(database.insertedFields?['storage_path'], storage.uploadedPath);
    expect(database.insertedLinks, [target]);
  });

  test('upload removes its object when metadata insertion fails', () async {
    final database = _FakeEvidenceDataSource()..failInsertEvidence = true;
    final storage = _FakeEvidenceObjectStorage();
    final repository = _repository(database, storage);

    await expectLater(
      repository.uploadFile(
        title: 'Garden photo',
        fileName: 'garden.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      throwsStateError,
    );

    expect(storage.removedPaths, [storage.uploadedPath]);
  });

  test('storage deletion failure keeps evidence metadata available', () async {
    final database = _FakeEvidenceDataSource();
    final storage = _FakeEvidenceObjectStorage()..failRemove = true;
    final repository = _repository(database, storage);
    final record = _fileRecord();

    await expectLater(repository.deleteEvidence(record), throwsStateError);

    expect(database.deletedIds, isEmpty);
  });

  test('opening file evidence requests a short-lived signed URL', () async {
    final storage = _FakeEvidenceObjectStorage();
    final repository = _repository(_FakeEvidenceDataSource(), storage);

    final url = await repository.openUrl(_fileRecord());

    expect(url, 'https://storage.example/signed');
    expect(storage.signedPath, 'user-1/garden.jpg');
    expect(storage.signedExpiry, const Duration(minutes: 2));
  });
}

EvidenceRepository _repository(
  _FakeEvidenceDataSource database,
  _FakeEvidenceObjectStorage storage,
) => EvidenceRepositoryImpl(
  database: database,
  storage: storage,
  currentUserId: () => 'user-1',
);

EvidenceRecord _fileRecord() => EvidenceRecord(
  id: 'evidence-1',
  userId: 'user-1',
  kind: EvidenceKind.file,
  title: 'Garden photo',
  description: '',
  fileName: 'garden.jpg',
  contentType: 'image/jpeg',
  sizeBytes: 3,
  storagePath: 'user-1/garden.jpg',
  createdAt: DateTime.utc(2026, 10, 21),
  updatedAt: DateTime.utc(2026, 10, 21),
);

class _FakeEvidenceDataSource implements EvidenceDataSource {
  final List<String> deletedIds = [];
  final List<EvidenceTarget> insertedLinks = [];
  Map<String, dynamic>? insertedFields;
  bool failInsertEvidence = false;

  @override
  Future<List<Map<String, dynamic>>> listEvidenceRows(String userId) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> listLinkRows(String userId) async =>
      const [];

  @override
  Future<List<EvidenceTarget>> listTargets(String userId) async => const [];

  @override
  Future<Map<String, dynamic>> insertEvidence(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    insertedFields = fields;
    if (failInsertEvidence) throw StateError('Metadata save failed');
    return {
      'id': 'evidence-1',
      'user_id': userId,
      ...fields,
      'created_at': '2026-10-21T00:00:00Z',
      'updated_at': '2026-10-21T00:00:00Z',
    };
  }

  @override
  Future<void> insertLinks(
    String userId,
    String evidenceId,
    List<EvidenceTarget> targets,
  ) async {
    insertedLinks.addAll(targets);
  }

  @override
  Future<void> deleteEvidence(String userId, String id) async {
    deletedIds.add(id);
  }
}

class _FakeEvidenceObjectStorage implements EvidenceObjectStorage {
  final List<String> removedPaths = [];
  String? uploadedPath;
  String? signedPath;
  Duration? signedExpiry;
  bool failRemove = false;

  @override
  Future<void> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedPath = path;
  }

  @override
  Future<void> remove(String path) async {
    if (failRemove) throw StateError('Storage removal failed');
    removedPaths.add(path);
  }

  @override
  Future<String> createSignedUrl(String path, Duration expiresIn) async {
    signedPath = path;
    signedExpiry = expiresIn;
    return 'https://storage.example/signed';
  }
}
