import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/profile/domain/profile.dart';

void main() {
  test('occupation choices cover varied fields and preserve custom roles', () {
    expect(
      OccupationCategory.agriculture.label,
      'Agriculture, forestry, and fisheries',
    );
    expect(
      OccupationCategory.virtualAssistance.databaseValue,
      'virtual_assistance_remote_operations',
    );
    expect(
      OccupationCategory.fromDatabase('education_training'),
      OccupationCategory.education,
    );

    const background = ProfileBackground(
      displayName: 'Sam',
      username: 'sam_user',
      occupationCategory: OccupationCategory.other,
      occupationTitle: 'Community seed librarian',
    );
    expect(
      background.toDatabaseFields()['occupation_title'],
      'Community seed librarian',
    );
  });

  test(
    'existing basic profile parses with optional background fields empty',
    () {
      final profile = ProfileBackground.fromJson({
        'user_id': 'user-1',
        'display_name': 'Avery Student',
        'username': 'avery_student',
      });

      expect(profile.headline, isEmpty);
      expect(profile.bio, isEmpty);
      expect(profile.occupationCategory, isNull);
      expect(profile.interests, isEmpty);
    },
  );

  test('current volunteer experience permits no organization or end date', () {
    const draft = ExperienceDraft(
      title: 'Community garden coordinator',
      type: ExperienceType.volunteering,
      isCurrent: true,
      description: 'Organize weekly planting sessions.',
    );

    final record = ExperienceRecord.fromJson({
      'id': 'experience-1',
      'user_id': 'user-1',
      ...draft.toDatabaseFields(),
      'created_at': '2026-10-20T00:00:00Z',
      'updated_at': '2026-10-20T00:00:00Z',
    });

    expect(record.organization, isNull);
    expect(record.endDate, isNull);
    expect(record.isCurrent, isTrue);
    expect(record.type, ExperienceType.volunteering);
  });

  test('education record distinguishes courses in progress and completed', () {
    const draft = EducationDraft(
      title: 'Certificate in sustainable farming',
      institution: 'Regional Learning Centre',
      status: EducationStatus.inProgress,
    );
    final fields = draft.toDatabaseFields();
    expect(fields['title'], 'Certificate in sustainable farming');
    expect(fields['status'], 'in_progress');
    expect(
      EducationStatus.fromDatabase('completed'),
      EducationStatus.completed,
    );
  });
}
