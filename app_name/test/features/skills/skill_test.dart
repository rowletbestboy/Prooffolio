import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/skills/domain/skill.dart';

void main() {
  test('skill draft trims names and serializes its self-reported state', () {
    const draft = SkillDraft(
      name: '  Dart  ',
      category: SkillCategory.technologyDigital,
      status: SkillStatus.applied,
    );

    expect(draft.toRpcParameters(null, const ['project-1']), {
      'p_skill_id': null,
      'p_name': 'Dart',
      'p_category': 'technology_digital',
      'p_status': 'applied',
      'p_project_ids': ['project-1'],
    });
    expect(SkillStatus.applied.label, 'Applied in a project');
    expect(SkillCategory.technologyDigital.label, 'Technology and digital work');
  });

  test('skill categories include non-technology fields and retain legacy values', () {
    expect(SkillCategory.agricultureEnvironment.label, 'Agriculture and environment');
    expect(SkillCategory.virtualAssistanceRemoteOperations.databaseValue,
        'virtual_assistance_remote_operations');
    expect(
      SkillCategory.fromDatabase('programming_languages'),
      SkillCategory.technologyDigital,
    );
  });

  test('skill parser keeps linked project titles from repository data', () {
    final skill = Skill.fromJson({
      'id': 'skill-1',
      'user_id': 'user-1',
      'name': 'Dart',
      'category': 'technology_digital',
      'status': 'practicing',
      'project_ids': ['project-1'],
      'project_titles': ['Campus planner'],
      'created_at': '2026-10-20T00:00:00Z',
      'updated_at': '2026-10-20T00:00:00Z',
    });

    expect(skill.status, SkillStatus.practicing);
    expect(skill.projectTitles, ['Campus planner']);
  });
}
