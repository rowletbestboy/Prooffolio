import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> listProjects();
  Future<Project> createProject(ProjectDraft draft);
  Future<Project> updateProject(String id, ProjectDraft draft);
  Future<void> deleteProject(String id);
}

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Project>> listProjects() async {
    final rows = await _client
        .from('projects')
        .select()
        .order('updated_at', ascending: false);
    return rows.map((row) => Project.fromJson(row)).toList(growable: false);
  }

  @override
  Future<Project> createProject(ProjectDraft draft) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Please sign in again.');
    final row = await _client
        .from('projects')
        .insert({...draft.toDatabaseFields(), 'user_id': userId})
        .select()
        .single();
    return Project.fromJson(row);
  }

  @override
  Future<Project> updateProject(String id, ProjectDraft draft) async {
    final row = await _client
        .from('projects')
        .update({
          ...draft.toDatabaseFields(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return Project.fromJson(row);
  }

  @override
  Future<void> deleteProject(String id) async {
    final deleted = await _client
        .from('projects')
        .delete()
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) throw StateError('Project could not be deleted.');
  }
}
