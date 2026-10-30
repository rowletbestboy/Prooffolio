import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/core/theme/app_colors.dart';
import 'package:app_name/core/theme/app_theme.dart';
import 'package:app_name/core/widgets/app_brand_mark.dart';
import 'package:app_name/features/projects/data/project_repository.dart';
import 'package:app_name/features/projects/domain/project.dart';
import 'package:app_name/features/projects/presentation/projects_screen.dart';

void main() {
  testWidgets('empty project list explains the first useful action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProjectsScreen(repository: _FakeProjectRepository()),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Projects'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    expect(find.text('No projects yet'), findsOneWidget);
    expect(find.text('Add your first project'), findsOneWidget);
    expect(find.textContaining('real work'), findsOneWidget);
  });

  testWidgets('user can create, edit and confirm deletion of a project', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProjectRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProjectsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your first project'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );

    final titleDecorator = tester.widget<InputDecorator>(
      find
          .descendant(
            of: find.byKey(const Key('projectTitleField')),
            matching: find.byType(InputDecorator),
          )
          .first,
    );
    expect(titleDecorator.decoration.fillColor, AppColors.surfaceSubtle);
    await tester.enterText(
      find.byKey(const Key('projectTitleField')),
      'Campus planner',
    );
    await tester.enterText(
      find.byKey(const Key('projectSummaryField')),
      'A schedule tool',
    );
    await tester.scrollUntilVisible(
      find.text(
        'This project is saved as a private draft. You can choose what to share later.',
      ),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      _containerDecoration(
        tester,
        find.text(
          'This project is saved as a private draft. You can choose what to share later.',
        ),
      ).borderRadius,
      BorderRadius.circular(AppTheme.controlRadius),
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(repository.projects.single.title, 'Campus planner');
    expect(find.text('Campus planner'), findsOneWidget);
    expect(_cardMaterial(tester).color, AppColors.white);

    await tester.tap(find.text('Campus planner'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(AppBrandMark),
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text(
        'This project is private. Add supporting links and files from your Evidence library.',
      ),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      _containerDecoration(
        tester,
        find.text(
          'This project is private. Add supporting links and files from your Evidence library.',
        ),
      ).borderRadius,
      BorderRadius.circular(AppTheme.cardRadius),
    );
    await tester.tap(find.byTooltip('Edit project'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('projectTitleField')),
      'Campus planner 2',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.projects.single.title, 'Campus planner 2');
    expect(find.text('Campus planner 2'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Campus planner 2'), findsOneWidget);
    await tester.tap(find.text('Campus planner 2'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete project'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this project?'), findsOneWidget);
    expect(_dialogBackground(tester), AppColors.white);
    await tester.tap(find.text('Delete project').last);
    await tester.pumpAndSettle();

    expect(repository.projects, isEmpty);
    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('project form validates required title and malformed URLs', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProjectRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProjectsScreen(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add your first project'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a project title'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('projectTitleField')), 'Build');
    await tester.dragUntilVisible(
      find.byKey(const Key('projectRepositoryUrlField')),
      find.byType(Scrollable).first,
      const Offset(0, -360),
    );
    await tester.enterText(
      find.byKey(const Key('projectRepositoryUrlField')),
      'not a url',
    );
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid http or https URL'), findsOneWidget);
    expect(repository.projects, isEmpty);
  });
}

BoxDecoration _containerDecoration(WidgetTester tester, Finder descendant) {
  final container = tester.widget<Container>(
    find.ancestor(of: descendant, matching: find.byType(Container)).first,
  );
  return container.decoration! as BoxDecoration;
}

Material _cardMaterial(WidgetTester tester) {
  final card = find.byType(Card).first;
  return tester.widget<Material>(
    find.descendant(of: card, matching: find.byType(Material)).first,
  );
}

Color? _dialogBackground(WidgetTester tester) => Theme.of(
  tester.element(find.byType(AlertDialog)),
).dialogTheme.backgroundColor;

class _FakeProjectRepository implements ProjectRepository {
  final List<Project> projects = [];
  int _nextId = 1;

  @override
  Future<List<Project>> listProjects() async => List.of(projects);

  @override
  Future<Project> createProject(ProjectDraft draft) async {
    final now = DateTime.utc(2026, 10, 20);
    final project = Project.fromJson({
      ...draft.toDatabaseFields(),
      'id': 'project-${_nextId++}',
      'user_id': 'user-1',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    projects.add(project);
    return project;
  }

  @override
  Future<Project> updateProject(String id, ProjectDraft draft) async {
    final index = projects.indexWhere((project) => project.id == id);
    final previous = projects[index];
    final updated = Project.fromJson({
      ...draft.toDatabaseFields(),
      'id': previous.id,
      'user_id': previous.userId,
      'created_at': previous.createdAt.toIso8601String(),
      'updated_at': DateTime.utc(2026, 10, 21).toIso8601String(),
    });
    projects[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProject(String id) async {
    projects.removeWhere((project) => project.id == id);
  }
}
