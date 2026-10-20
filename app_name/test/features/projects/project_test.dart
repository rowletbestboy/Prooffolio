import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/projects/domain/project.dart';

void main() {
  test('project draft trims text and serializes its record fields', () {
    final draft = ProjectDraft(
      title: '  Campus planner  ',
      summary: '  A schedule tool  ',
      technologies: const ['Flutter', 'Dart'],
      keyFeatures: const ['Plan a week', 'Share a schedule'],
      status: ProjectStatus.completed,
    );

    expect(draft.toDatabaseFields(), {
      'title': 'Campus planner',
      'summary': 'A schedule tool',
      'problem_statement': '',
      'description': '',
      'key_features': ['Plan a week', 'Share a schedule'],
      'technologies': ['Flutter', 'Dart'],
      'contribution': '',
      'challenges': '',
      'lessons_learned': '',
      'repository_url': null,
      'demo_url': null,
      'start_date': null,
      'end_date': null,
      'status': 'completed',
      'publication_status': 'draft',
    });
  });

  test('project model reads database dates and lists', () {
    final project = Project.fromJson({
      'id': 'project-1',
      'user_id': 'user-1',
      'title': 'Campus planner',
      'summary': null,
      'problem_statement': '',
      'description': 'A planner for students.',
      'key_features': ['Schedule', 'Share'],
      'technologies': ['Flutter'],
      'contribution': '',
      'challenges': '',
      'lessons_learned': '',
      'repository_url': null,
      'demo_url': null,
      'start_date': '2026-01-02',
      'end_date': null,
      'status': 'in_progress',
      'publication_status': 'draft',
      'created_at': '2026-01-02T00:00:00.000Z',
      'updated_at': '2026-01-03T00:00:00.000Z',
    });

    expect(project.id, 'project-1');
    expect(project.status, ProjectStatus.inProgress);
    expect(project.startDate, DateTime(2026, 1, 2));
    expect(project.technologies, ['Flutter']);
  });
}
