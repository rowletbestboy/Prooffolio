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
      expect(profile.photoPath, isNull);
      expect(profile.contactEmail, isNull);
      expect(profile.additionalLinks, isEmpty);
    },
  );

  test('profile contact and photo fields round-trip through database JSON', () {
    const profile = ProfileBackground(
      displayName: 'Avery Student',
      username: 'avery_student',
      headline: 'Community educator',
      bio: 'I build accessible learning programs.',
      photoPath: 'user-1/portrait.webp',
      contactEmail: 'avery@example.com',
      phone: '+1 555 0100',
      githubUrl: 'https://github.com/avery',
      linkedInUrl: 'https://www.linkedin.com/in/avery',
      upworkUrl: 'https://www.upwork.com/freelancers/~avery',
      jobstreetUrl: 'https://www.jobstreet.com/profile/avery',
      whatsAppNumber: '+15550100',
      additionalLinks: [
        ProfileContactLink(
          label: 'Writing',
          url: 'https://example.com/writing',
        ),
      ],
    );

    final fields = profile.toDatabaseFields();
    final restored = ProfileBackground.fromJson({
      'user_id': 'user-1',
      ...fields,
    });

    expect(fields['photo_path'], 'user-1/portrait.webp');
    expect(fields['contact_email'], 'avery@example.com');
    expect(fields['linkedin_url'], 'https://www.linkedin.com/in/avery');
    expect(fields['upwork_url'], 'https://www.upwork.com/freelancers/~avery');
    expect(restored.headline, profile.headline);
    expect(restored.bio, profile.bio);
    expect(restored.photoPath, profile.photoPath);
    expect(restored.contactEmail, profile.contactEmail);
    expect(restored.phone, profile.phone);
    expect(restored.githubUrl, profile.githubUrl);
    expect(restored.linkedInUrl, profile.linkedInUrl);
    expect(restored.upworkUrl, profile.upworkUrl);
    expect(restored.jobstreetUrl, profile.jobstreetUrl);
    expect(restored.whatsAppNumber, profile.whatsAppNumber);
    expect(restored.additionalLinks.single.label, 'Writing');
    expect(restored.additionalLinks.single.url, 'https://example.com/writing');
  });

  test('profile accepts absent and null optional contact fields', () {
    final absent = ProfileBackground.fromJson({
      'display_name': 'Avery',
      'username': 'avery',
    });
    final nullValues = ProfileBackground.fromJson({
      'display_name': 'Avery',
      'username': 'avery',
      'photo_path': null,
      'contact_email': null,
      'additional_links': null,
    });

    expect(absent.photoPath, isNull);
    expect(absent.additionalLinks, isEmpty);
    expect(nullValues.photoPath, isNull);
    expect(nullValues.contactEmail, isNull);
    expect(nullValues.additionalLinks, isEmpty);
  });

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
