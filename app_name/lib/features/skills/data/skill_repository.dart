import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/skill.dart';

abstract interface class SkillRepository {
  Future<List<Skill>> listSkills();
  Future<Skill> saveSkill({
    String? id,
    required SkillDraft draft,
    required List<String> projectIds,
  });
  Future<void> deleteSkill(String id);
}

class SupabaseSkillRepository implements SkillRepository {
  SupabaseSkillRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Skill>> listSkills() async {
    final skillRows = await _client
        .from('skills')
        .select()
        .order('name', ascending: true);
    if (skillRows.isEmpty) return const [];

    final ids = skillRows.map((row) => row['id'] as String).toList();
    final links = await _client
        .from('project_skills')
        .select('skill_id, project_id')
        .inFilter('skill_id', ids);
    final projectRows = await _client.from('projects').select('id, title');
    final titlesById = {
      for (final row in projectRows)
        row['id'] as String: row['title'] as String,
    };
    final idsBySkill = <String, List<String>>{};
    for (final row in links) {
      idsBySkill
          .putIfAbsent(row['skill_id'] as String, () => [])
          .add(row['project_id'] as String);
    }

    return skillRows
        .map((row) {
          final skillId = row['id'] as String;
          final projectIds = idsBySkill[skillId] ?? const <String>[];
          return Skill.fromJson({
            ...row,
            'project_ids': projectIds,
            'project_titles': projectIds
                .map((projectId) => titlesById[projectId])
                .whereType<String>()
                .toList(growable: false),
          });
        })
        .toList(growable: false);
  }

  @override
  Future<Skill> saveSkill({
    String? id,
    required SkillDraft draft,
    required List<String> projectIds,
  }) async {
    final savedId =
        await _client.rpc(
              'save_skill_with_projects',
              params: draft.toRpcParameters(id, projectIds),
            )
            as String;
    final skills = await listSkills();
    return skills.firstWhere((skill) => skill.id == savedId);
  }

  @override
  Future<void> deleteSkill(String id) async {
    final deleted = await _client
        .from('skills')
        .delete()
        .eq('id', id)
        .select('id');
    if (deleted.isEmpty) throw StateError('Skill could not be deleted.');
  }
}
