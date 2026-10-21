import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/evidence.dart';

abstract interface class EvidenceRepository {
  Future<List<EvidenceRecord>> listEvidence();
  Future<List<EvidenceTarget>> listTargets();
  Future<EvidenceRecord> addUrl({
    required String title,
    required String sourceUrl,
    String description,
    List<EvidenceTarget> targets,
  });
  Future<EvidenceRecord> uploadFile({
    required String title,
    required String fileName,
    required String? mimeType,
    required Uint8List bytes,
    String description,
    List<EvidenceTarget> targets,
  });
  Future<String> openUrl(EvidenceRecord record);
  Future<void> deleteEvidence(EvidenceRecord record);
}

abstract interface class EvidenceDataSource {
  Future<List<Map<String, dynamic>>> listEvidenceRows(String userId);
  Future<List<Map<String, dynamic>>> listLinkRows(String userId);
  Future<List<EvidenceTarget>> listTargets(String userId);
  Future<Map<String, dynamic>> insertEvidence(
    String userId,
    Map<String, dynamic> fields,
  );
  Future<void> insertLinks(
    String userId,
    String evidenceId,
    List<EvidenceTarget> targets,
  );
  Future<void> deleteEvidence(String userId, String id);
}

abstract interface class EvidenceObjectStorage {
  Future<void> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });
  Future<void> remove(String path);
  Future<String> createSignedUrl(String path, Duration expiresIn);
}

class EvidenceRepositoryImpl implements EvidenceRepository {
  EvidenceRepositoryImpl({
    required this.database,
    required this.storage,
    required this.currentUserId,
  });

  final EvidenceDataSource database;
  final EvidenceObjectStorage storage;
  final String Function() currentUserId;

  String get _userId {
    final id = currentUserId();
    if (id.isEmpty) throw const AuthException('Please sign in again.');
    return id;
  }

  @override
  Future<List<EvidenceTarget>> listTargets() => database.listTargets(_userId);

  @override
  Future<List<EvidenceRecord>> listEvidence() async {
    final userId = _userId;
    final rows = await database.listEvidenceRows(userId);
    if (rows.isEmpty) return const [];

    final links = await database.listLinkRows(userId);
    final availableTargets = await database.listTargets(userId);
    final targetsByKey = {
      for (final target in availableTargets) _targetKey(target): target,
    };
    final linksByEvidence = <String, List<EvidenceTarget>>{};
    for (final link in links) {
      final target = targetsByKey[_targetKeyFromJson(link)];
      if (target != null) {
        (linksByEvidence[link['evidence_id'] as String] ??= []).add(target);
      }
    }

    return rows
        .map(
          (row) => EvidenceRecord.fromJson(
            row,
            targets: linksByEvidence[row['id'] as String] ?? const [],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<EvidenceRecord> addUrl({
    required String title,
    required String sourceUrl,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) async {
    final safeUrl = EvidenceUrlPolicy.parse(sourceUrl);
    if (safeUrl == null) {
      throw const EvidenceInputException(
        'Enter a valid link that starts with http:// or https://.',
      );
    }
    if (title.trim().isEmpty) {
      throw const EvidenceInputException('Enter a title for this evidence.');
    }
    final userId = _userId;
    final draft = EvidenceDraft.url(
      title: title,
      sourceUrl: safeUrl.toString(),
      description: description,
      targets: targets,
    );
    final row = await database.insertEvidence(userId, draft.toDatabaseFields());
    final id = row['id'] as String;
    try {
      await database.insertLinks(userId, id, targets);
    } catch (_) {
      try {
        await database.deleteEvidence(userId, id);
      } catch (_) {
        // Preserve the original link error for the caller.
      }
      rethrow;
    }
    return EvidenceRecord.fromJson(row, targets: targets);
  }

  @override
  Future<EvidenceRecord> uploadFile({
    required String title,
    required String fileName,
    required String? mimeType,
    required Uint8List bytes,
    String description = '',
    List<EvidenceTarget> targets = const [],
  }) async {
    if (title.trim().isEmpty) {
      throw const EvidenceInputException('Enter a title for this evidence.');
    }
    final validationError = EvidenceFilePolicy.validate(
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
    if (validationError != null) {
      throw EvidenceInputException(validationError);
    }
    final contentType = EvidenceFilePolicy.contentTypeFor(fileName)!;
    final userId = _userId;
    final storagePath = '$userId/${_randomName(fileName)}';
    await storage.uploadBytes(
      path: storagePath,
      bytes: bytes,
      contentType: contentType,
    );

    final draft = EvidenceDraft.file(
      title: title,
      fileName: fileName,
      contentType: contentType,
      sizeBytes: bytes.length,
      storagePath: storagePath,
      description: description,
      targets: targets,
    );
    Map<String, dynamic>? row;
    try {
      row = await database.insertEvidence(userId, draft.toDatabaseFields());
      await database.insertLinks(userId, row['id'] as String, targets);
      return EvidenceRecord.fromJson(row, targets: targets);
    } catch (error) {
      Object? rollbackError;
      try {
        await storage.remove(storagePath);
      } catch (cleanupError) {
        throw EvidenceCleanupException(error, cleanupError);
      }
      if (row != null) {
        try {
          await database.deleteEvidence(userId, row['id'] as String);
        } catch (error) {
          rollbackError = error;
        }
      }
      if (rollbackError != null) {
        throw EvidenceCleanupException(error, rollbackError);
      }
      rethrow;
    }
  }

  @override
  Future<String> openUrl(EvidenceRecord record) async {
    if (record.kind == EvidenceKind.url) {
      final uri = EvidenceUrlPolicy.parse(record.sourceUrl ?? '');
      if (uri == null) {
        throw const EvidenceInputException('This link is invalid.');
      }
      return uri.toString();
    }
    final path = record.storagePath;
    if (path == null || path.isEmpty) {
      throw StateError('This evidence file is unavailable.');
    }
    return storage.createSignedUrl(path, const Duration(minutes: 2));
  }

  @override
  Future<void> deleteEvidence(EvidenceRecord record) async {
    final userId = _userId;
    if (record.userId != userId) {
      throw const AuthException('You can only delete your own evidence.');
    }
    if (record.kind == EvidenceKind.file && record.storagePath != null) {
      await storage.remove(record.storagePath!);
    }
    await database.deleteEvidence(userId, record.id);
  }
}

class SupabaseEvidenceDataSource implements EvidenceDataSource {
  SupabaseEvidenceDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> listEvidenceRows(String userId) async {
    final rows = await _client
        .from('evidence_records')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> listLinkRows(String userId) async {
    final rows = await _client
        .from('evidence_links')
        .select('evidence_id, target_type, target_id')
        .eq('user_id', userId);
    return rows;
  }

  @override
  Future<List<EvidenceTarget>> listTargets(String userId) async {
    final results = await Future.wait([
      _client
          .from('projects')
          .select('id, title')
          .eq('user_id', userId)
          .order('title'),
      _client
          .from('skills')
          .select('id, name')
          .eq('user_id', userId)
          .order('name'),
      _client
          .from('experience_records')
          .select('id, title')
          .eq('user_id', userId)
          .order('title'),
      _client
          .from('portfolio_records')
          .select('id, title, record_type')
          .eq('user_id', userId)
          .order('title'),
    ]);
    return [
      for (final row in results[0])
        EvidenceTarget(
          type: EvidenceTargetType.project,
          id: row['id'] as String,
          title: row['title'] as String,
        ),
      for (final row in results[1])
        EvidenceTarget(
          type: EvidenceTargetType.skill,
          id: row['id'] as String,
          title: row['name'] as String,
        ),
      for (final row in results[2])
        EvidenceTarget(
          type: EvidenceTargetType.experience,
          id: row['id'] as String,
          title: row['title'] as String,
        ),
      for (final row in results[3])
        EvidenceTarget(
          type: EvidenceTargetType.portfolioRecord,
          id: row['id'] as String,
          title: row['title'] as String,
        ),
    ];
  }

  @override
  Future<Map<String, dynamic>> insertEvidence(
    String userId,
    Map<String, dynamic> fields,
  ) async => await _client
      .from('evidence_records')
      .insert({...fields, 'user_id': userId})
      .select()
      .single();

  @override
  Future<void> insertLinks(
    String userId,
    String evidenceId,
    List<EvidenceTarget> targets,
  ) async {
    if (targets.isEmpty) return;
    await _client.from('evidence_links').insert([
      for (final target in targets)
        {
          'user_id': userId,
          'evidence_id': evidenceId,
          'target_type': target.type.databaseValue,
          'target_id': target.id,
        },
    ]);
  }

  @override
  Future<void> deleteEvidence(String userId, String id) async {
    final rows = await _client
        .from('evidence_records')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw StateError('Evidence could not be deleted.');
  }
}

class SupabaseEvidenceObjectStorage implements EvidenceObjectStorage {
  SupabaseEvidenceObjectStorage(this._client);

  final SupabaseClient _client;

  @override
  Future<void> uploadBytes({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from('evidence')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  Future<void> remove(String path) async {
    await _client.storage.from('evidence').remove([path]);
  }

  @override
  Future<String> createSignedUrl(String path, Duration expiresIn) async =>
      await _client.storage
          .from('evidence')
          .createSignedUrl(path, expiresIn.inSeconds);
}

class SupabaseEvidenceRepository extends EvidenceRepositoryImpl {
  SupabaseEvidenceRepository(SupabaseClient client)
    : super(
        database: SupabaseEvidenceDataSource(client),
        storage: SupabaseEvidenceObjectStorage(client),
        currentUserId: () => client.auth.currentUser?.id ?? '',
      );
}

class EvidenceInputException implements Exception {
  const EvidenceInputException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EvidenceCleanupException implements Exception {
  const EvidenceCleanupException(this.originalError, this.cleanupError);
  final Object originalError;
  final Object cleanupError;

  @override
  String toString() =>
      'Evidence could not be saved and its uploaded file could not be removed.';
}

String _randomName(String originalName) {
  final extension = originalName.substring(originalName.lastIndexOf('.') + 1);
  final random = Random.secure();
  final token = List.generate(
    32,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '$token.$extension';
}

String _targetKey(EvidenceTarget target) =>
    '${target.type.databaseValue}:${target.id}';

String _targetKeyFromJson(Map<String, dynamic> row) =>
    '${row['target_type']}:${row['target_id']}';
