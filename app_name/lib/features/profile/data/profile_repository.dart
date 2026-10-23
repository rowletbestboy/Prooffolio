import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile.dart';

abstract interface class ProfileRepository {
  Future<bool> hasProfile(String userId);

  Future<void> saveProfile({
    required String displayName,
    required String username,
  });
}

abstract interface class ProfileBackgroundRepository {
  Future<ProfileBackground?> loadProfile(String userId);
  Future<void> saveBackground(String userId, ProfileBackground background);
  Future<List<EducationRecord>> listEducation(String userId);
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  });
  Future<void> deleteEducation(String userId, String id);
  Future<List<ExperienceRecord>> listExperience(String userId);
  Future<ExperienceRecord> saveExperience(
    String userId,
    ExperienceDraft draft, {
    String? id,
  });
  Future<void> deleteExperience(String userId, String id);
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes,
    String fileName,
    String contentType,
  );
  Future<void> deleteProfilePhoto(String userId, String path);
  Future<String> createProfilePhotoSignedUrl(String path);
  Future<Uint8List> downloadProfilePhoto(String userId, String path);
}

class SupabaseProfileRepository
    implements ProfileRepository, ProfileBackgroundRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<bool> hasProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<void> saveProfile({
    required String displayName,
    required String username,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Please sign in again.');
    await _client.from('profiles').upsert({
      'user_id': userId,
      'display_name': displayName.trim(),
      'username': username.trim().toLowerCase(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<ProfileBackground?> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : ProfileBackground.fromJson(row);
  }

  @override
  Future<void> saveBackground(
    String userId,
    ProfileBackground background,
  ) async {
    final rows = await _client
        .from('profiles')
        .update({
          ...background.toDatabaseFields(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .select('user_id');
    if (rows.isEmpty) throw StateError('Profile could not be saved.');
  }

  @override
  Future<List<EducationRecord>> listEducation(String userId) async {
    final rows = await _client
        .from('education_records')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows
        .map((row) => EducationRecord.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  }) async {
    final fields = {
      ...draft.toDatabaseFields(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = id == null
        ? await _client
              .from('education_records')
              .insert({...fields, 'user_id': userId})
              .select()
              .single()
        : await _client
              .from('education_records')
              .update(fields)
              .eq('user_id', userId)
              .eq('id', id)
              .select()
              .single();
    return EducationRecord.fromJson(row);
  }

  @override
  Future<void> deleteEducation(String userId, String id) async {
    final rows = await _client
        .from('education_records')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Education record could not be deleted.');
    }
  }

  @override
  Future<List<ExperienceRecord>> listExperience(String userId) async {
    final rows = await _client
        .from('experience_records')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows
        .map((row) => ExperienceRecord.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<ExperienceRecord> saveExperience(
    String userId,
    ExperienceDraft draft, {
    String? id,
  }) async {
    final fields = {
      ...draft.toDatabaseFields(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final row = id == null
        ? await _client
              .from('experience_records')
              .insert({...fields, 'user_id': userId})
              .select()
              .single()
        : await _client
              .from('experience_records')
              .update(fields)
              .eq('user_id', userId)
              .eq('id', id)
              .select()
              .single();
    return ExperienceRecord.fromJson(row);
  }

  @override
  Future<void> deleteExperience(String userId, String id) async {
    final rows = await _client
        .from('experience_records')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Experience record could not be deleted.');
    }
  }

  @override
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async {
    _requireCurrentUser(userId);
    if (bytes.isEmpty || bytes.lengthInBytes > 5000000) {
      throw ArgumentError.value(
        bytes.lengthInBytes,
        'bytes',
        'Invalid photo size.',
      );
    }
    if (!_profilePhotoTypes.contains(contentType)) {
      throw ArgumentError.value(
        contentType,
        'contentType',
        'Unsupported photo type.',
      );
    }
    final extension = switch (contentType) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => throw ArgumentError.value(contentType, 'contentType'),
    };
    final randomName = List.generate(
      32,
      (_) => Random.secure().nextInt(16).toRadixString(16),
    ).join();
    final path = '$userId/$randomName.$extension';
    await _client.storage
        .from('profile-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return path;
  }

  @override
  Future<void> deleteProfilePhoto(String userId, String path) async {
    _requireOwnedPhotoPath(userId, path);
    await _client.storage.from('profile-photos').remove([path]);
  }

  @override
  Future<String> createProfilePhotoSignedUrl(String path) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Please sign in again.');
    _requireOwnedPhotoPath(userId, path);
    return _client.storage
        .from('profile-photos')
        .createSignedUrl(path, const Duration(minutes: 2).inSeconds);
  }

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) async {
    _requireOwnedPhotoPath(userId, path);
    return _client.storage.from('profile-photos').download(path);
  }

  void _requireCurrentUser(String userId) {
    if (_client.auth.currentUser?.id != userId) {
      throw const AuthException('Please sign in again.');
    }
  }

  void _requireOwnedPhotoPath(String userId, String path) {
    _requireCurrentUser(userId);
    if (!path.startsWith('$userId/')) {
      throw const AuthException('You can only access your own profile photo.');
    }
  }
}

const _profilePhotoTypes = {'image/jpeg', 'image/png', 'image/webp'};
