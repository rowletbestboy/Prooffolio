import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_name/features/profile/data/profile_repository.dart';
import 'package:app_name/features/profile/domain/profile.dart';
import 'package:app_name/features/profile/presentation/profile_background_screen.dart';
import 'package:app_name/features/dashboard/presentation/home_shell.dart';

void main() {
  testWidgets('profile action opens the background editor from Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          profileRepository: _FakeProfileBackgroundRepository(),
          profileUserId: 'user-1',
        ),
      ),
    );

    await tester.tap(find.byTooltip('Profile and background'));
    await tester.pumpAndSettle();

    expect(find.text('Profile and background'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
  });

  testWidgets('profile can be saved without a degree or work history', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profileHeadlineField')),
      'Growing community gardens',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.background.headline, 'Growing community gardens');
    expect(repository.education, isEmpty);
    expect(repository.experience, isEmpty);
    expect(find.text('Profile saved'), findsOneWidget);
  });

  testWidgets('profile explains photo privacy and exposes contact inputs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(
          repository: _FakeProfileBackgroundRepository(),
          userId: 'user-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(
        'This is the photo used in your portfolio and photo resume. '
        'It stays private until you choose to include it.',
      ),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'This is the photo used in your portfolio and photo resume. '
        'It stays private until you choose to include it.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Contact details'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('profileContactEmailField')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileUpworkUrlField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('profileUpworkUrlField')), findsOneWidget);
  });

  testWidgets('profile photo is uploaded to the private profile path', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(
          repository: repository,
          userId: 'user-1',
          photoPicker: _FakeProfilePhotoPicker(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('chooseProfilePhotoButton')),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('chooseProfilePhotoButton')));
    await tester.pumpAndSettle();

    expect(repository.background.photoPath, 'user-1/profile.png');
    expect(find.text('Profile photo saved'), findsOneWidget);
  });

  testWidgets('contact save preserves saved background fields', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..background = const ProfileBackground(
        displayName: 'Avery Student',
        username: 'avery_student',
        headline: 'Community educator',
        bio: 'I build accessible learning programs.',
        occupationCategory: OccupationCategory.education,
        occupationTitle: 'Program facilitator',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('profileContactEmailField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('profileContactEmailField')),
      'avery@example.com',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('profileUpworkUrlField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('profileUpworkUrlField')),
      'www.upwork.com/freelancers/~avery',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.background.contactEmail, 'avery@example.com');
    expect(
      repository.background.upworkUrl,
      'https://www.upwork.com/freelancers/~avery',
    );
    expect(repository.background.headline, 'Community educator');
    expect(repository.background.bio, 'I build accessible learning programs.');
    expect(
      repository.background.occupationCategory,
      OccupationCategory.education,
    );
    expect(repository.background.occupationTitle, 'Program facilitator');
  });

  testWidgets('unsafe Upwork URL is not saved', (WidgetTester tester) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('profileUpworkUrlField')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('profileUpworkUrlField')),
      'javascript:alert(1)',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.background.upworkUrl, isNull);
    expect(find.text('Enter a valid Upwork profile URL'), findsOneWidget);
  });

  testWidgets('users can save a labeled custom profile link', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add another link'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add another link'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profileAdditionalLinkLabel-0')),
      'Writing',
    );
    await tester.enterText(
      find.byKey(const Key('profileAdditionalLinkUrl-0')),
      'example.com/writing',
    );
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.background.additionalLinks.single.label, 'Writing');
    expect(
      repository.background.additionalLinks.single.url,
      'https://example.com/writing',
    );
  });

  testWidgets('education entry requires a title before it can be saved', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add education'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add education'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save education'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a course or qualification'), findsOneWidget);
    expect(repository.education, isEmpty);

    await tester.enterText(
      find.byKey(const Key('educationTitleField')),
      'Community horticulture course',
    );
    await tester.tap(find.text('Save education'));
    await tester.pumpAndSettle();

    expect(repository.education.single.title, 'Community horticulture course');
  });

  testWidgets('profile save failure is visible to the user', (
    WidgetTester tester,
  ) async {
    final repository = _FakeProfileBackgroundRepository()
      ..failBackgroundSave = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileBackgroundScreen(repository: repository, userId: 'user-1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile could not be saved. Try again.'), findsOneWidget);
  });

  testWidgets(
    'user can select a broad occupation and add education and volunteer work',
    (WidgetTester tester) async {
      final repository = _FakeProfileBackgroundRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileBackgroundScreen(
            repository: repository,
            userId: 'user-1',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final occupationField = find.byKey(const Key('occupationCategoryField'));
      await tester.scrollUntilVisible(
        occupationField,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(occupationField);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('occupationSearchField')),
        'Education',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Education and training').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('occupationTitleField')),
        'Primary teacher',
      );

      await tester.scrollUntilVisible(
        find.text('Add education'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add education'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('educationTitleField')),
        'Bachelor of Education',
      );
      await tester.enterText(
        find.byKey(const Key('educationInstitutionField')),
        'State University',
      );
      await tester.tap(find.text('Save education'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Add experience'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add experience'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('experienceTitleField')),
        'Community reading tutor',
      );
      await tester.tap(find.byKey(const Key('experienceTypeField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volunteering').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('experienceCurrentField')));
      await tester.tap(find.text('Save experience'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save profile'));
      await tester.pumpAndSettle();

      expect(
        repository.background.occupationCategory,
        OccupationCategory.education,
      );
      expect(repository.background.occupationTitle, 'Primary teacher');
      expect(repository.education.single.title, 'Bachelor of Education');
      expect(repository.experience.single.title, 'Community reading tutor');
      expect(repository.experience.single.organization, isNull);
      expect(repository.experience.single.type, ExperienceType.volunteering);
      expect(repository.experience.single.isCurrent, isTrue);
    },
  );
}

class _FakeProfileBackgroundRepository implements ProfileBackgroundRepository {
  ProfileBackground background = const ProfileBackground(
    displayName: 'Avery Student',
    username: 'avery_student',
  );
  final List<EducationRecord> education = [];
  final List<ExperienceRecord> experience = [];
  bool failBackgroundSave = false;
  int _nextId = 0;

  @override
  Future<ProfileBackground?> loadProfile(String userId) async => background;

  @override
  Future<void> saveBackground(String userId, ProfileBackground value) async {
    if (failBackgroundSave) throw StateError('Save failed');
    background = value;
  }

  @override
  Future<String> uploadProfilePhoto(
    String userId,
    Uint8List bytes,
    String fileName,
    String contentType,
  ) async => '$userId/$fileName';

  @override
  Future<void> deleteProfilePhoto(String userId, String path) async {}

  @override
  Future<String> createProfilePhotoSignedUrl(String path) async =>
      'https://example.com/$path';

  @override
  Future<Uint8List> downloadProfilePhoto(String userId, String path) async =>
      Uint8List(0);

  @override
  Future<List<EducationRecord>> listEducation(String userId) async =>
      List.of(education);

  @override
  Future<EducationRecord> saveEducation(
    String userId,
    EducationDraft draft, {
    String? id,
  }) async {
    final now = DateTime.utc(2026, 10, 20);
    final record = EducationRecord(
      id: id ?? 'education-${++_nextId}',
      userId: userId,
      title: draft.title,
      institution: draft.institution,
      level: draft.level,
      status: draft.status,
      startDate: draft.startDate,
      endDate: draft.endDate,
      description: draft.description,
      createdAt: now,
      updatedAt: now,
    );
    education.removeWhere((item) => item.id == record.id);
    education.add(record);
    return record;
  }

  @override
  Future<void> deleteEducation(String userId, String id) async {
    education.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<ExperienceRecord>> listExperience(String userId) async =>
      List.of(experience);

  @override
  Future<ExperienceRecord> saveExperience(
    String userId,
    ExperienceDraft draft, {
    String? id,
  }) async {
    final now = DateTime.utc(2026, 10, 20);
    final record = ExperienceRecord(
      id: id ?? 'experience-${++_nextId}',
      userId: userId,
      title: draft.title,
      organization: draft.organization,
      type: draft.type,
      startDate: draft.startDate,
      endDate: draft.endDate,
      isCurrent: draft.isCurrent,
      description: draft.description,
      createdAt: now,
      updatedAt: now,
    );
    experience.removeWhere((item) => item.id == record.id);
    experience.add(record);
    return record;
  }

  @override
  Future<void> deleteExperience(String userId, String id) async {
    experience.removeWhere((item) => item.id == id);
  }
}

class _FakeProfilePhotoPicker implements ProfilePhotoPicker {
  @override
  Future<PickedProfilePhoto?> pickPhoto() async => PickedProfilePhoto(
    fileName: 'profile.png',
    mimeType: 'image/png',
    bytes: _tinyPng,
  );
}

final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j5QAAAABJRU5ErkJggg==',
);
