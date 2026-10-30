import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/core/widgets/app_icon_tile.dart';
import 'package:app_name/features/projects/data/project_repository.dart';
import 'package:app_name/features/projects/domain/project.dart';
import 'package:app_name/features/skills/data/skill_repository.dart';
import 'package:app_name/features/skills/domain/skill.dart';
import 'package:app_name/features/skills/presentation/skills_screen.dart';

void main() {
  testWidgets('Skills page header carries the Prooffolio brand', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SkillsScreen(
          repository: _FakeSkillRepository(),
          projectRepository: _FakeProjectRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, AppColors.deepNavy);
    expect(appBar.toolbarHeight, 56);
    final brandMark = tester.widget<AppBrandMark>(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
    );
    expect(brandMark.inverse, isTrue);
  });

  testWidgets('empty skills state makes adding a skill the clear next step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
    final iconTile = tester.widget<AppIconTile>(find.byType(AppIconTile).first);
    expect(iconTile.color, AppColors.teal);
    expect(iconTile.backgroundColor, AppColors.tealContainer);
  });

  testWidgets('skills can be filtered by category and searched', (
    WidgetTester tester,
  ) async {
    final skills = _FakeSkillRepository(
      initialSkills: [
        _skill(
          id: 'figma',
          name: 'Figma',
          category: SkillCategory.artsMediaDesign,
          status: SkillStatus.applied,
          projectTitles: const ['Campus planner'],
        ),
        _skill(
          id: 'flutter',
          name: 'Flutter',
          category: SkillCategory.technologyDigital,
          status: SkillStatus.learning,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SkillsScreen(
          repository: skills,
          projectRepository: _FakeProjectRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Figma'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Flutter'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Flutter'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('skillCategoryFilter-artsMediaDesign')),
    );
    await tester.tap(
      find.byKey(const Key('skillCategoryFilter-artsMediaDesign')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Figma'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skillSearchToggle')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('skillSearchField')), 'figma');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Figma'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Figma'), findsOneWidget);
  });

  testWidgets('skills are grouped with project-link counts from saved data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SkillsScreen(
          repository: _FakeSkillRepository(
            initialSkills: [
              _skill(
                id: 'figma',
                name: 'Figma',
                category: SkillCategory.artsMediaDesign,
                status: SkillStatus.applied,
                projectTitles: const ['Campus planner'],
              ),
              _skill(
                id: 'flutter',
                name: 'Flutter',
                category: SkillCategory.technologyDigital,
                status: SkillStatus.learning,
              ),
            ],
          ),
          projectRepository: _FakeProjectRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 skills'), findsOneWidget);
    expect(find.text('1 linked to projects'), findsOneWidget);
    expect(
      find.byKey(const Key('skillCategoryGroup-artsMediaDesign')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('skillCategoryGroup-technologyDigital')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('skillCategoryGroup-technologyDigital')),
      findsOneWidget,
    );
  });

  testWidgets('user can create a skill and link it to a project', (
    WidgetTester tester,
  ) async {
    final skills = _FakeSkillRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SkillsScreen(
          repository: skills,
          projectRepository: _FakeProjectRepository()..projects.add(_project()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first skill'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    final statusField = tester.widget<DropdownButton<SkillStatus>>(
      find.descendant(
        of: find.byKey(const Key('skillStatusField')),
        matching: find.byType(DropdownButton<SkillStatus>),
      ),
    );
    expect(
      statusField.borderRadius,
      BorderRadius.circular(AppTheme.controlRadius),
    );
    final nameDecorator = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byKey(const Key('skillNameField')),
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(nameDecorator.decoration.fillColor, AppColors.surfaceSubtle);
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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color ==
                AppColors.indigoContainer,
      ),
      findsWidgets,
    );
    await tester.ensureVisible(find.byTooltip('Skill actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Skill actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete skill'));
    await tester.pumpAndSettle();
    expect(_dialogBackground(tester), AppColors.white);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(skills.skills, hasLength(1));
  });

  testWidgets('skill form requires a name', (WidgetTester tester) async {
    final skills = _FakeSkillRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

Color? _dialogBackground(WidgetTester tester) => Theme.of(
  tester.element(find.byType(AlertDialog)),
).dialogTheme.backgroundColor;

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
  _FakeSkillRepository({List<Skill> initialSkills = const []})
    : skills = List.of(initialSkills);

  final List<Skill> skills;
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

Skill _skill({
  required String id,
  required String name,
  required SkillCategory category,
  required SkillStatus status,
  List<String> projectTitles = const [],
}) => Skill(
  id: id,
  userId: 'user-1',
  name: name,
  category: category,
  status: status,
  projectIds: projectTitles.isEmpty ? const [] : const ['project-1'],
  projectTitles: projectTitles,
  createdAt: DateTime.utc(2026, 10, 20),
  updatedAt: DateTime.utc(2026, 10, 20),
);

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
