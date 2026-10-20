import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/projects/data/project_repository.dart';
import 'package:app_name/features/projects/domain/project.dart';
import 'package:app_name/features/skills/data/skill_repository.dart';
import 'package:app_name/features/skills/domain/skill.dart';
import 'package:app_name/features/skills/presentation/skills_screen.dart';

void main() {
  testWidgets('empty skills state makes adding a skill the clear next step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsScreen(
          repository: _FakeSkillRepository(),
          projectRepository: _FakeProjectRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No skills yet'), findsOneWidget);
    expect(find.text('Add your first skill'), findsOneWidget);
    expect(find.textContaining('self-reported'), findsOneWidget);
  });

  testWidgets('user can create a skill and link it to a project', (
    WidgetTester tester,
  ) async {
    final skills = _FakeSkillRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsScreen(
          repository: skills,
          projectRepository: _FakeProjectRepository()..projects.add(_project()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first skill'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('skillNameField')), 'Dart');
    await tester.tap(find.byKey(const Key('skillStatusField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Applied in a project').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skillProject-project-1')));
    await tester.tap(find.text('Save skill'));
    await tester.pumpAndSettle();

    expect(skills.skills.single.name, 'Dart');
    expect(skills.skills.single.projectIds, ['project-1']);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.textContaining('Campus planner'), findsOneWidget);
    expect(find.text('Applied in a project'), findsOneWidget);
  });

  testWidgets('skill form requires a name', (WidgetTester tester) async {
    final skills = _FakeSkillRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SkillsScreen(
          repository: skills,
          projectRepository: _FakeProjectRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your first skill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save skill'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a skill name'), findsOneWidget);
    expect(skills.skills, isEmpty);
  });
}

Project _project() {
  final now = DateTime.utc(2026, 10, 20);
  return Project.fromJson({
    'id': 'project-1',
    'user_id': 'user-1',
    'title': 'Campus planner',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
}

class _FakeSkillRepository implements SkillRepository {
  final List<Skill> skills = [];
  int _nextId = 1;

  @override
  Future<List<Skill>> listSkills() async => List.of(skills);

  @override
  Future<Skill> saveSkill({
    String? id,
    required SkillDraft draft,
    required List<String> projectIds,
  }) async {
    final now = DateTime.utc(2026, 10, 20);
    final existingIndex = skills.indexWhere((skill) => skill.id == id);
    final skillId = id ?? 'skill-${_nextId++}';
    final skill = Skill(
      id: skillId,
      userId: 'user-1',
      name: draft.name.trim(),
      category: draft.category,
      status: draft.status,
      projectIds: List.of(projectIds),
      projectTitles: projectIds.map((_) => 'Campus planner').toList(),
      createdAt: existingIndex == -1 ? now : skills[existingIndex].createdAt,
      updatedAt: now,
    );
    if (existingIndex == -1) {
      skills.add(skill);
    } else {
      skills[existingIndex] = skill;
    }
    return skill;
  }

  @override
  Future<void> deleteSkill(String id) async {
    skills.removeWhere((skill) => skill.id == id);
  }
}

class _FakeProjectRepository implements ProjectRepository {
  final List<Project> projects = [];

  @override
  Future<List<Project>> listProjects() async => List.of(projects);

  @override
  Future<Project> createProject(ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<Project> updateProject(String id, ProjectDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteProject(String id) => throw UnimplementedError();
}
